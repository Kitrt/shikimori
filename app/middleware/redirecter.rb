class Redirecter
  VALID_HOSTS = ShikimoriDomain::HOSTS + AnimeOnlineDomain::HOSTS

  def initialize app
    @app = app
  end

  def call env
    request = Rack::Request.new env

    if !VALID_HOSTS.include? request.host
      [301, {'Location' => request.url.sub(request.host, Shikimori::DOMAIN)}, []]

    elsif request.host.starts_with? 'www.'
      [301, {'Location' => request.url.sub('//www.', '//')}, self]

    elsif request.url.end_with?('/') && request.path != '/'
      [301, {'Location' => request.url.sub(/\/$/, '')}, []]

    elsif request.url.end_with?('&') && request.path != '/'
      [301, {'Location' => request.url.sub(/&$/, '')}, []]

    elsif request.url.end_with?('.html')
      [301, {'Location' => request.url.sub(/.html$/, '')}, []]

    else
      @app.call(env)
    end
  end
end
