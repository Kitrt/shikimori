json.content render(
  partial: 'versions/version',
  collection: @versions.processed,
  formats: :html
)

if @versions.postloader?
  json.postloader render(
    'blocks/postloader',
    next_url: @versions.next_page_url
  )
end
