class ImportStylesForUsers < ActiveRecord::Migration
  def up
    puts 'generating styles'
    styles = User.includes(:preferences).map do |user|
      user.styles.build name: '', css: css(user.preferences)
    end
    puts 'importing styles'
    Style.import styles, validate: false
  end

  def down
    Style.delete_all
  end

private

  def css preferences
    styles = []

    if preferences.page_border
      styles << Style::PAGE_BORDER_CSS
    end

    if preferences.page_background.to_f > 0
      color = 255 - preferences.page_background.to_f.ceil
      styles << Style::PAGE_BORDER_CSS % [color, color, color]
    end

    if preferences.body_background.present?
      styles << Style::BODY_BACKGROUND_CSS % [background_css(preferences)]
    end

    styles.join("\n")
  end

  def background_css preferences
    background = preferences.body_background

    if background =~ %r{\A(https?:)?//}
      url = UrlGenerator.instance.camo_url background
      "background: url(#{url}) fixed no-repeat"
    else
      fixed_background = background.gsub(BbCodes::UrlTag::REGEXP) do
        UrlGenerator.instance.camo_url $LAST_MATCH_INFO[:url]
      end
      "background: #{fixed_background}"
    end
  end
end
