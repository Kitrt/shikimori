class ContestMatch < ApplicationRecord
  UNDEFINED = 'undefined variant'

  belongs_to :round, class_name: ContestRound.name, touch: true
  belongs_to :left, polymorphic: true
  belongs_to :right, polymorphic: true

  has_many :contest_user_votes
  has_many :votes, class_name: ContestUserVote.name, dependent: :destroy

  delegate :contest, :strategy, to: :round

  scope :with_user_vote, lambda { |user, ip|
    if user
      joins("left join #{ContestUserVote.table_name} cuv on cuv.contest_match_id=#{table_name}.id and (cuv.id is null or cuv.user_id=#{sanitize user.id} or cuv.ip=#{sanitize ip})")
        .group("#{table_name}.id, cuv.item_id")
        .select("#{table_name}.*, cuv.item_id as voted_id")
    else
      select("#{table_name}.*, null::integer as voted_id")
    end
  }

  scope :with_votes, lambda {
    joins("left join #{ContestUserVote.table_name} cuv on cuv.contest_match_id=#{table_name}.id")
      .group("#{table_name}.id")
      .select("#{table_name}.*,
               sum(case when cuv.item_id=0 then 1 else 0 end) as refrained_votes,
               sum(case when cuv.item_id=left_id then 1 else 0 end) as left_votes,
               sum(case when cuv.item_id=right_id then 1 else 0 end) as right_votes")
  }

  state_machine :state, initial: :created do
    state :created
    state :started do
      # голосование за конкретный вариант
      def vote_for(variant, user, ip)
        votes.where(user_id: user.id).delete_all
        votes.create! user: user, contest_match_id: id, item_id: variant.to_s == 'none' ? 0 : send("#{variant}_id"), ip: ip
      end

      # обновление статуса пользоваетля в зависимости от возможности голосовать далее
      def update_user(user, ip)
        if round.matches.with_user_vote(user, ip).select(&:started?).all?(&:voted?)
          user.update_attribute round.contest.user_vote_key, false
        end
      end
    end
    state :finished

    event :start do
      transition :created => :started,
        if: ->(match) { match.started_on && match.started_on <= Time.zone.today }
    end
    event :finish do
      transition :started => :finished,
        if: ->(match) { match.finished_on && match.finished_on < Time.zone.today }
    end
  end

  # за какой вариант проголосовал пользователь
  def voted_for
    if voted_id && voted_id.zero?
      :none
    elsif voted_id == right_id && voted_id.nil?
      :auto
    elsif voted_id == left_id
      :left
    elsif voted_id == right_id
      :right
    else
      nil
    end
  end

  def can_vote?
    started?
  end

  # за какой вариант проголосовал пользователь (работает при выборке со scope with_user_vote)
  def voted?
    voted_id.present? || (right_type.nil?)
  end

  # победитель
  def winner
    if winner_id == left_id
      left
    else
      right
    end
  end

  # проигравший
  def loser
    if winner_id == left_id
      right
    else
      left
    end
  end

  # число голосов за левого кандидата
  def left_votes
    @left_votes ||= self[:left_votes] ||
      cached_votes.select {|v| v.item_id == left_id }.size
  end

  # число голосов за правого кандидата
  def right_votes
    @right_votes ||= self[:right_votes] ||
      cached_votes.select {|v| v.item_id == right_id }.size
  end

  # число голосов за правого кандидата
  def refrained_votes
    @refrained_votes ||= self[:refrained_votes] ||
      cached_votes.select {|v| v.item_id == 0 }.size
  end

private

  def cached_votes
    @cached_votes ||= votes.to_a
  end
end
