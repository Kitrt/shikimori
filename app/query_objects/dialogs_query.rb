class DialogsQuery < SimpleQueryBase
  pattr_initialize :user

  def fetch page, limit
    Message
      .where(id: latest_message_ids(page, limit))
      .includes(:linked, :from, :to)
      .order(id: :desc)
      .map {|v| Dialog.new(user, v) }
  end

private

  def latest_message_ids page, limit
    Message
      .where(kind: MessageType::Private)
      .where.not(from_id: ignores_ids, to_id: ignores_ids)
      .where(
        "(from_id = :user_id) or
         (to_id = :user_id and is_deleted_by_to=false)",
        user_id: user.id)
      .group("case when from_id = #{user.id} then to_id else from_id end")
      .order('max(id) desc')
      .select('max(id) as id')
      .offset(limit * (page-1))
      .limit(limit + 1)
  end

  def ignores_ids
    @ignores_ids ||= user.ignores.map(&:target_id) << 0
  end
end
