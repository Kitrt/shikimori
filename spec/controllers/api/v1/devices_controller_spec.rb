require 'cancan/matchers'

describe Api::V1::DevicesController, :show_in_doc do
  before { sign_in user }
  let(:user) { create :user }

  describe '#index' do
    let!(:device_1) { create :device, user: user }
    let!(:device_2) { create :device }
    before { get :index, format: :json }

    it do
      expect(assigns(:devices)).to have(1).item
      expect(response).to have_http_status :success
      expect(response.content_type).to eq 'application/json'
    end
  end

  describe '#create' do
    before { post :create, device: { user_id: user.id, token: 'test', platform: 'ios', name: 'test'}, format: :json }

    it do
      expect(assigns :device).to be_persisted
      expect(response).to have_http_status :created
      expect(response.content_type).to eq 'application/json'
    end
  end

  describe '#destroy' do
    let(:device) { create :device, user: user }
    before { delete :destroy, id: device.id, format: :json }

    it do
      expect(assigns :device).to be_destroyed
      expect(response).to have_http_status :no_content
      expect(response.content_type).to eq 'application/json'
    end
  end

  describe 'permissions' do
    subject { Ability.new user }

    context 'own_device' do
      let(:device) { build :device, user: user }
      it { should be_able_to :manage, device }
    end

    context 'foreign_device' do
      let(:device) { build :device }
      it { should_not be_able_to :manage, device }
    end

    context 'guest' do
      subject { Ability.new nil }
      let(:device) { build :device, user: user }
      it { should_not be_able_to :manage, device }
    end
  end
end
