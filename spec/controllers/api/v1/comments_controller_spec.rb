describe Api::V1::CommentsController do
  let(:user) { create :user, :user }
  let(:topic) { create :entry, user: user }
  let(:comment) { create :comment, commentable: topic, user: user }

  describe '#show', :show_in_doc do
    before { get :show, id: comment.id, format: :json }

    it do
      expect(response).to have_http_status :success
      expect(response.content_type).to eq 'application/json'
    end
  end

  describe '#index', :show_in_doc do
    let!(:comment_1) { create :comment, user: user, commentable: user }
    let!(:comment_2) { create :comment, user: user, commentable: user }

    before { get :index, commentable_type: User.name, commentable_id: user.id, page: 1, limit: 10, desc: '1', format: :json }

    it do
      expect(response).to have_http_status :success
      expect(response.content_type).to eq 'application/json'
    end
  end

  describe '#create' do
    before { sign_in user }

    context 'success', :show_in_doc do
      before { post :create, comment: { commentable_id: topic.id, commentable_type: topic.class.name, body: 'test', offtopic: false, review: false }, format: :json }

      it do
        expect(response).to have_http_status :success
        expect(response.content_type).to eq 'application/json'
        expect(assigns(:comment)).to be_persisted
      end
    end

    context 'failure' do
      before { post :create, comment: { body: 'test', offtopic: false, review: false }, format: :json }

      it do
        expect(response).to have_http_status 422
        expect(response.content_type).to eq 'application/json'
      end
    end
  end

  describe '#update' do
    before { sign_in user }
    let(:make_request) { patch :update, id: comment.id, comment: { body: 'testzxc' }, format: :json }

    context 'success', :show_in_doc do
      before { make_request }

      it do
        expect(response).to have_http_status :success
        expect(response.content_type).to eq 'application/json'
        expect(assigns(:comment).body).to eq 'testzxc'
      end
    end

    context 'forbidden' do
      let(:comment) { create :comment, commentable: topic }
      it { expect{make_request}.to raise_error CanCan::AccessDenied }
    end
  end

  describe '#destroy' do
    before { sign_in user }
    let(:make_request) { delete :destroy, id: comment.id, format: :json }

    context 'success', :show_in_doc do
      before { make_request }
      it do
        expect(response).to have_http_status :success
        expect(response.content_type).to eq 'application/json'
      end
    end

    context 'forbidden' do
      let(:comment) { create :comment, commentable: topic }
      it { expect{make_request}.to raise_error CanCan::AccessDenied }
    end
  end
end
