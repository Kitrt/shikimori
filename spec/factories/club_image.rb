FactoryGirl.define do
  factory :club_image do
    club nil
    user { seed :user }
    image { open "#{Rails.root}/spec/images/anime.jpg" }
  end
end