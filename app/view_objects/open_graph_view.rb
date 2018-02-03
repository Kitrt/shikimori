class OpenGraphView < ViewObjectBase
  prepend ActiveCacher.instance
  # instance_cache :styles, :hot_topics, :moderation_policy

  attr_reader :page_title
  attr_writer :description, :notice
  attr_accessor :keywords, :noindex, :nofollow

  def initialize
    @page_title = []
    @notice = nil
    @noindex = nil
    @nofollow = nil
    @keywords = nil
    @description = nil
  end

  PAGE_TITLE_SEPARATOR = ' / '

  def site_name
    h.ru_host? ? Shikimori::NAME_RU : Shikimori::NAME_EN
  end

  def canonical_url # rubocop:disable AbcSize
    url =
      if h.params[:page].present? && h.params[:page].to_s.match?(/^\d+$/)
        h.current_url(page: nil)
      else
        h.request.url
      end

    url.gsub(/\?.*/, '')
  end

  def page_title= value
    @page_title.push HTMLEntities.new.decode(value)
  end

  def headline allow_not_set = false
    @page_title.last || (
      allow_not_set ? site_name : raise('open_graph.page_title is not set')
    )
  end

  def notice
    @notice || @description
  end

  def description
    @description || @notice
  end

  def meta_title
    titles = @page_title.any? ? @page_title : [site_name]

    <<~TITLE.strip.delete("\n")
      #{'[DEV] ' if Rails.env.development?}
      #{titles.reverse.join PAGE_TITLE_SEPARATOR}
    TITLE
  end

  def meta_robots
    return if canonical_url != h.request.url

    content = [
      ('noindex' if noindex),
      ('nofollow' if nofollow)
    ].compact

    content.join ',' if content.any?
  end

  def meta_image
    return unless resource.respond_to?(:image)

    h.cdn_image resource, :original
  end

private

  def resource
    h.controller.instance_variable_get('@resource')
  end
end
