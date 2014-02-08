class VkVideoExtractor
  def initialize url
    @url = url
  end

  def fetch
    OpenStruct.new(
      image_url: parsed_data['jpg'],
      oid: parsed_data['oid'],
      vid: parsed_data['vid'],
      hash2: parsed_data['hash2']
    )
  rescue OpenURI::HTTPError => e
  rescue EmptyContent => e
  end

private
  def parsed_data
    @parsed_data ||= Rails.cache.fetch @url, expires_in: 2.weeks do
      data = fetch_page.match(/vars = ({.*?});\\nvar/) || raise(EmptyContent, @url)
      JSON.parse data[1].gsub(/\\/, '')
    end
  end

  def fetch_page
    @fetched_page ||= open(@url).read
  end
end
