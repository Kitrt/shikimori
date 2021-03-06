# frozen_string_literal: true

describe Topic::Create do
  include_context :seeds

  subject(:topic) { Topic::Create.call faye, params, locale }

  let(:user) { create :user }
  let(:faye) { FayeService.new user, nil }
  let(:locale) { :en }

  context 'valid params' do
    let(:params) do
      {
        user_id: user.id,
        forum_id: animanga_forum.id,
        title: 'title',
        body: 'text'
      }
    end
    it do
      expect(topic).to be_persisted
      expect(topic).to have_attributes params.merge(locale: locale.to_s)
    end
  end

  context 'invalid params' do
    let(:params) do
      {
        forum_id: animanga_forum.id,
        title: 'title',
        body: 'text'
      }
    end
    it do
      expect(topic).to be_new_record
      expect(topic).to have_attributes params.merge(locale: locale.to_s)
      expect(topic.errors).to have(1).item
    end
  end
end

