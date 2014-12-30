require 'cancan/matchers'

describe UserRate do
  describe 'relations' do
    it { should belong_to :target }
    it { should belong_to :user }
    it { should belong_to :anime }
    it { should belong_to :manga }
  end

  describe 'validations' do
    it { should validate_presence_of :target }
    it { should validate_presence_of :user }
  end

  describe 'callbacks' do
    context '#create' do
      let(:user_rate) { build :user_rate, status: 0 }
      after { user_rate.save }

      it { expect(user_rate).to receive :log_created }
      it { expect(user_rate).to receive :smart_process_changes }
    end

    context '#update' do
      let(:user_rate) { create :user_rate, status: 0 }
      after { user_rate.update status: 1 }

      it { expect(user_rate).to_not receive :log_created }
      it { expect(user_rate).to receive :smart_process_changes }
    end

    context '#destroy' do
      let(:user_rate) { create :user_rate, status: 0 }
      after { user_rate.destroy }

      it { expect(user_rate).to receive :log_deleted }
      it { expect(user_rate).to_not receive :smart_process_changes }
    end
  end

  describe 'instance methods' do
    let(:episodes) { 10 }
    let(:volumes) { 15 }
    let(:chapters) { 100 }

    describe '#anime?' do
      subject { user_rate.anime? }

      context 'anime' do
        let(:user_rate) { build :user_rate, target_type: 'Anime' }
        it { should be true }
      end

      context 'manga' do
        let(:user_rate) { build :user_rate, target_type: 'Manga' }
        it { should be false }
      end
    end

    describe '#manga?' do
      subject { user_rate.manga? }

      context 'anime' do
        let(:user_rate) { build :user_rate, target_type: 'Anime' }
        it { should be false }
      end

      context 'manga' do
        let(:user_rate) { build :user_rate, target_type: 'Manga' }
        it { should be true }
      end
    end

    describe '#smart_process_changes' do
      context 'onhold with episode' do
        subject(:user_rate) { create :user_rate, :on_hold, target: build_stubbed(:anime, episodes: 99), episodes: 6 }
        it { should be_on_hold }
        its(:episodes) { should eq 6 }
      end

      context 'dropped with full episode' do
        subject(:user_rate) { create :user_rate, :dropped, target: build_stubbed(:anime, episodes: 3), episodes: 3 }
        it { should be_dropped }
        its(:episodes) { should eq 3 }
      end

      context 'dropped with parital episode' do
        subject(:user_rate) { create :user_rate, :dropped, target: build_stubbed(:anime, episodes: 3), episodes: 2 }
        it { should be_dropped }
        its(:episodes) { should eq 2 }
      end

      context 'planned with full episode' do
        subject { create :user_rate, :planned, target: build_stubbed(:anime, episodes: 3), episodes: 3 }
        it { should be_completed }
        its(:episodes) { should eq 3 }
      end

      describe 'status change' do
        let(:user_rate) { build :user_rate, :watching, target: build_stubbed(:anime) }
        after { user_rate.save }
        it { expect(user_rate).to receive :status_changed }
      end

      describe 'nil rewatches' do
        let(:user_rate) { build :user_rate, :watching, target: build_stubbed(:anime), rewatches: nil }
        before { user_rate.save }
        its(:rewatches) { should be_zero }
      end
    end

    describe '#status_changed' do
      before do
        expect(UserHistory).to receive(:add).with(
          user_rate.user,
          user_rate.target,
          UserHistoryAction::Status,
          UserRate.statuses[new_status],
          UserRate.statuses[old_status]
        )
      end

      subject(:user_rate) { create :user_rate, old_status, target: target }
      let(:update_params) {{ status: new_status }}
      before { user_rate.update update_params }

      describe 'to planned' do
        let(:new_status) { :planned }

        context 'anime' do
          let(:target) { build_stubbed :anime, episodes: 20 }

          context 'completed' do
            let(:old_status) { :completed }
            its(:episodes) { should eq target.episodes }
          end

          context 'watching' do
            let(:old_status) { :watching }
            its(:episodes) { should eq 0 }
          end
        end

        context 'manga' do
          let(:target) { build_stubbed :manga, volumes: 20, chapters: 25 }

          context 'completed' do
            let(:old_status) { :completed }
            its(:volumes) { should eq target.volumes }
            its(:chapters) { should eq target.chapters }
          end

          context 'watching' do
            let(:old_status) { :watching }
            its(:volumes) { should eq 0 }
            its(:chapters) { should eq 0 }
          end
        end
      end

      context 'to rewatching' do
        let(:old_status) { :completed }
        let(:new_status) { :rewatching }

        context 'anime' do
          let(:target) { build_stubbed :anime, episodes: 20 }
          its(:episodes) { should eq 0 }
        end

        context 'manga' do
          let(:target) { build_stubbed :manga, volumes: 20, chapters: 20 }
          its(:volumes) { should eq 0 }
          its(:chapters) { should eq 0 }
        end
      end

      context 'to rewatching with episodes' do
        let(:target) { build_stubbed :anime, episodes: 20 }
        let(:old_status) { :completed }
        let(:new_status) { :rewatching }
        let(:new_episodes) { 10 }
        let(:update_params) {{ status: new_status, episodes: new_episodes }}

        its(:episodes) { should eq new_episodes }
      end

      context 'to onhold with 0 episodes from completed' do
        let(:target) { build_stubbed :anime, episodes: 20 }
        let(:old_status) { :completed }
        let(:new_status) { :on_hold }
        let(:new_episodes) { 0 }
        let(:update_params) {{ status: new_status, episodes: new_episodes }}

        it { should be_on_hold }
        its(:episodes) { should eq 0 }
      end

      context 'to completed for ongoing w/o episodes' do
        subject(:user_rate) { create :user_rate, old_status, episodes: old_episodes, target: target }
        let(:target) { build_stubbed :anime, episodes: 0, status: AniMangaStatus::Ongoing }

        let(:old_episodes) { 3 }
        let(:old_status) { :watching }
        let(:new_status) { :completed }
        let(:update_params) {{ status: new_status }}

        it { should be_completed }
        its(:episodes) { should eq old_episodes }
      end
    end

    describe '#score_changed' do
      subject!(:user_rate) { create :user_rate, score: old_value }
      let(:old_value) { 5 }

      context 'nil value' do
        let(:old_value) { 0 }
        let(:new_value) { nil }

        before { expect(UserHistory).to_not receive :add }
        before { user_rate.update score: new_value }

        its(:score) { should eq old_value }
      end

      context 'regular change' do
        let(:new_value) { 8 }

        before { expect(UserHistory).to receive(:add).with user_rate.user, user_rate.target, UserHistoryAction::Rate, new_value, old_value }
        before { user_rate.update score: new_value }

        its(:score) { should eq new_value }
      end

      context 'negative value' do
        let(:new_value) { -1 }

        before { expect(UserHistory).to_not receive :add }
        before { user_rate.update score: new_value }

        its(:score) { should eq old_value }
      end

      context 'big value' do
        let(:new_value) { UserRate::MAXIMUM_SCORE + 1 }

        before { expect(UserHistory).to_not receive :add }
        before { user_rate.update score: new_value }

        its(:score) { should eq old_value }
      end
    end

    describe '#counter_changed' do
      subject!(:user_rate) { create :user_rate, target: target, episodes: old_value, volumes: old_value, chapters: old_value, status: old_status }

      let(:old_value) { 1 }
      let(:old_status) { :planned }
      let(:target_value) { 99 }

      context 'anime' do
        let(:target) { build_stubbed :anime, episodes: target_value }
        before { user_rate.update episodes: new_value }

        context 'regular_change' do
          before { expect(UserHistory).to receive(:add).with user_rate.user, user_rate.target, UserHistoryAction::Episodes, newest_value, new_value }
          before { user_rate.update episodes: 7 }

          let(:old_value) { 3 }
          let(:new_value) { 5 }
          let(:newest_value) { 7 }

          its(:episodes) { should eq newest_value }
        end

        context 'maximum number' do
          let(:target_value) { 0 }
          let(:new_value) { UserRate::MAXIMUM_EPISODES + 1 }
          its(:episodes) { should eq old_value }
        end

        context 'nil number' do
          let(:new_value) { nil }
          its(:episodes) { should eq 0 }
        end

        context 'negative number' do
          let(:new_value) { -1 }
          its(:episodes) { should eq 0 }
        end

        context 'greater than target number' do
          let(:target_value) { 99 }
          let(:new_value) { 100 }
          its(:episodes) { should eq target.episodes }
        end

        context 'started watching' do
          let(:old_value) { 0 }
          let(:new_value) { 5 }
          its(:watching?) { should be true }
        end

        context 'finished watching' do
          let(:new_value) { target_value }
          its(:episodes) { should eq target_value }
          its(:completed?) { should be true }
        end

        context 'stopped watching' do
          let(:old_value) { 1 }
          let(:new_value) { 0 }
          its(:planned?) { should be true }
        end

        context 'rewatching' do
          let(:old_status) { :rewatching }

          context 'started watching' do
            let(:old_value) { 0 }
            let(:new_value) { 1 }

            its(:episodes) { should eq new_value }
            its(:rewatching?) { should be true }
          end

          context 'finished watching' do
            let(:new_value) { target_value }

            its(:episodes) { should eq target_value }
            its(:rewatches) { should eq 1 }
            its(:completed?) { should be true }
          end
        end
      end

      context 'manga' do
        let(:other_value) { 200 }

        describe 'volumes' do
          let(:target) { build_stubbed :manga, volumes: target_value, chapters: other_value }
          before { user_rate.update volumes: new_value }

          context 'full read' do
            let(:new_value) { target_value }
            its(:volumes) { should eq target_value }
            its(:chapters) { should eq other_value }
            its(:completed?) { should be true }
          end

          context 'zero volumes' do
            let(:new_value) { 0 }
            its(:volumes) { should eq 0 }
            its(:chapters) { should eq 0 }
          end
        end

        describe 'chapters' do
          let(:target) { build_stubbed :manga, volumes: other_value, chapters: target_value }
          before { user_rate.update chapters: new_value }

          context 'full read' do
            let(:new_value) { target_value }
            its(:volumes) { should eq other_value }
            its(:chapters) { should eq target_value }
            its(:completed?) { should be true }
          end

          context 'zero chapters' do
            let(:new_value) { 0 }
            its(:volumes) { should eq 0 }
            its(:chapters) { should eq 0 }
          end
        end
      end
    end

    describe '#log_created' do
      subject(:user_rate) { build :user_rate, target: build_stubbed(:anime), user: build_stubbed(:user) }
      after { user_rate.save }
      before { expect(UserHistory).to receive(:add).with user_rate.user, user_rate.target, UserHistoryAction::Add }
    end

    describe '#log_deleted' do
      subject!(:user_rate) { create :user_rate, target: build_stubbed(:anime), user: build_stubbed(:user) }
      after { user_rate.destroy }
      before { expect(UserHistory).to receive(:add).with user_rate.user, user_rate.target, UserHistoryAction::Delete }
    end

    describe '#text_html' do
      subject { build :user_rate, text: "[b]test[/b]\ntest" }
      its(:text_html) { should eq '<strong>test</strong><br />test' }
    end

    describe '#status_name' do
      subject { build :user_rate, target_type: 'Anime' }
      its(:status_name) { should eq 'Запланировано' }
    end
  end

  describe 'permissions' do
    let(:user) { build_stubbed :user }
    subject { Ability.new user }

    context 'owner' do
      let(:user_rate) { build_stubbed :user_rate, user: user }
      it { should be_able_to :mangae, user_rate }
    end

    context 'guest' do
      let(:user_rate) { build_stubbed :user_rate }
      let(:user) { nil }
      it { should_not be_able_to :manage, user_rate }
    end

    context 'user' do
      let(:user_rate) { build_stubbed :user_rate }
      let(:user) { nil }
      it { should_not be_able_to :manage, user_rate }
    end
  end
end
