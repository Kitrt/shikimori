describe ProfilesController do
  let!(:user) { create :user }

  describe '#show' do
    before { get :show, params: { id: user.to_param } }
    it { expect(response).to have_http_status :success }
  end

  describe '#friends' do
    context 'without friends' do
      before { get :friends, params: { id: user.to_param } }
      it { expect(response).to redirect_to profile_url(user) }
    end

    context 'with friends' do
      let!(:friend_link) { create :friend_link, src: user, dst: create(:user) }
      before { get :friends, params: { id: user.to_param } }
      it { expect(response).to have_http_status :success }
    end
  end

  describe '#clubs' do
    context 'without clubs' do
      before { get :clubs, params: { id: user.to_param } }
      it { expect(response).to redirect_to profile_url(user) }
    end

    context 'with clubs' do
      let(:club) { create :club, :with_topics }
      let!(:club_role) { create :club_role, user: user, club: club }
      before { get :clubs, params: { id: user.to_param } }
      it { expect(response).to have_http_status :success }
    end
  end

  describe '#favourites' do
    context 'without favourites' do
      before { get :favourites, params: { id: user.to_param } }
      it { expect(response).to redirect_to profile_url(user) }
    end

    context 'with favourites' do
      let!(:favourite) { create :favourite, user: user, linked: create(:anime) }
      before { get :favourites, params: { id: user.to_param } }
      it { expect(response).to have_http_status :success }
    end
  end

  describe '#reviews' do
    let!(:review) { create :review, :with_topics, user: user }
    before { get :reviews, params: { id: user.to_param } }
    it { expect(response).to have_http_status :success }
  end

  describe '#feed' do
    let!(:comment) { create :comment, user: user, commentable: user }
    before { get :feed, params: { id: user.to_param } }
    it { expect(response).to have_http_status :success }
  end

  describe '#comments' do
    let!(:comment) { create :comment, user: user, commentable: user }
    before { get :comments, params: { id: user.to_param } }
    it { expect(response).to have_http_status :success }
  end

  describe '#summaries' do
    let!(:comment) { create :comment, :summary, user: user, commentable: user }
    before { get :summaries, params: { id: user.to_param } }
    it { expect(response).to have_http_status :success }
  end

  describe '#versions' do
    let(:anime) { create :anime }
    let!(:version) do
      create :version,
        user: user,
        item: anime,
        item_diff: { name: ['test', 'test2'] },
        state: :accepted
    end
    before { get :versions, params: { id: user.to_param } }

    it do
      expect(collection).to have(1).item
      expect(response).to have_http_status :success
    end
  end

  describe '#video_versions' do
    let(:anime_video) { create :anime_video }
    let!(:version) do
      create :version,
        user: user,
        item: anime_video,
        item_diff: { episode: ['1', '2'] },
        state: :accepted
    end
    before { get :video_versions, params: { id: user.to_param } }

    it do
      expect(collection).to have(1).item
      expect(response).to have_http_status :success
    end
  end

  describe '#videos_uploads' do
    let(:anime) { create :anime }
    let(:anime_video) { create :anime_video, anime: anime }
    let!(:anime_video_report) do
      create :anime_video_report, :uploaded, :accepted,
        user: user,
        anime_video: anime_video
    end
    before { get :video_uploads, params: { id: user.to_param } }
    it do
      expect(collection).to have(1).item
      expect(response).to have_http_status :success
    end
  end

  describe '#videos_reports' do
    let(:anime) { create :anime }
    let(:anime_video) { create :anime_video, anime: anime }
    let!(:anime_video_report) do
      create :anime_video_report, :broken, :accepted,
        user: user,
        anime_video: anime_video
    end
    before { get :video_reports, params: { id: user.to_param } }
    it do
      expect(collection).to have(1).item
      expect(response).to have_http_status :success
    end
  end

  describe '#ban' do
    before { get :ban, params: { id: user.to_param } }
    it { expect(response).to have_http_status :success }
  end

  #describe '#stats' do
    #before { get :stats, id: user.to_param }
    #it { expect(response).to have_http_status :success }
  #end

  describe '#edit' do
    let(:make_request) { get :edit, params: { id: user.to_param, page: page } }

    context 'when valid access' do
      before { sign_in user }
      before { make_request }

      describe 'account' do
        let(:page) { 'account' }
        it { expect(response).to have_http_status :success }
      end

      describe 'profile' do
        let(:page) { 'profile' }
        it { expect(response).to have_http_status :success }
      end

      describe 'password' do
        let(:page) { 'password' }
        it { expect(response).to have_http_status :success }
      end

      describe 'styles' do
        let!(:user) { create :user, :with_assign_style }
        let(:page) { 'styles' }
        it { expect(response).to have_http_status :success }
      end

      describe 'list' do
        let(:page) { 'list' }
        it { expect(response).to have_http_status :success }
      end

      describe 'notifications' do
        let(:page) { 'notifications' }
        it { expect(response).to have_http_status :success }
      end

      describe 'misc' do
        let(:page) { 'misc' }
        it { expect(response).to have_http_status :success }
      end
    end

    context 'when invalid access' do
      let(:page) { 'account' }
      it { expect { make_request }.to raise_error CanCan::AccessDenied }
    end
  end

  describe '#update' do
    let(:make_request) { patch :update, params: { id: user.to_param, page: 'account', user: update_params } }

    context 'when valid access' do
      before { sign_in user }

      context 'when success' do
        before { make_request }

        context 'common change' do
          let(:update_params) { { nickname: 'morr' } }

          it do
            expect(resource.nickname).to eq 'morr'
            expect(resource.errors).to be_empty
            expect(response).to redirect_to edit_profile_url(resource, page: 'account')
          end
        end

        context 'association change' do
          let(:user_2) { create :user }
          let(:update_params) { { ignored_user_ids: [user_2.id] } }

          it do
            expect(resource.ignores?(user_2)).to be true
            expect(resource.errors).to be_empty
          end
        end

        context 'password change' do
          context 'when current password is set' do
            let(:user) { create :user, password: '1234' }
            let(:update_params) { { current_password: '1234', password: 'yhn' } }

            it do
              expect(resource.valid_password?('yhn')).to be true
              expect(resource.errors).to be_empty
            end
          end

          context 'when current password is not set' do
            let(:user) { create :user, :without_password }
            let(:update_params) { { password: 'yhn' } }

            it do
              expect(resource.valid_password?('yhn')).to be true
              expect(resource.errors).to be_empty
            end
          end
        end
      end

      context 'when validation errors' do
        let!(:user_2) { create :user }
        let(:update_params) { { nickname: user_2.nickname } }
        before { make_request }

        it do
          expect(resource.errors).to_not be_empty
          expect(response).to have_http_status :success
        end
      end
    end

    context 'when invalid access' do
      let(:update_params) { { nickname: '123' } }
      it { expect { make_request }.to raise_error CanCan::AccessDenied }
    end
  end
end
