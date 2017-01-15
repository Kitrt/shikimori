# frozen_string_literal: true

describe Anidb::ParseDescription, :vcr do
  subject(:call) { described_class.call url }

  context 'valid anime url' do
    let(:url) { 'http://anidb.net/perl-bin/animedb.pl?show=anime&aid=3395' }
    it do
      is_expected.to eq(
        <<-TEXT.squish
          * Based on the manga by [Hiroe Rei].[br][br]When [Okajima Rokuro]
          (aka [i]Rock[/i]) visits Southeast Asia carrying a top
          secret disk, he is kidnapped by pirates riding in the torpedo boat,
          [i]Black Lagoon[/i]. Although he thought he would be rescued soon,
          the company actually abandons him, and sends mercenaries to retrieve
          the secret disk. He narrowly escapes with his life, but has nowhere
          to go. He gives up his name and past, and resolves to live as a
          member of the Black Lagoon.[source]AnimeNfo[/source]
        TEXT
      )
    end
  end

  context 'valid character url' do
    let(:url) { 'http://anidb.net/perl-bin/animedb.pl?show=character&charid=3444' }
    it do
      is_expected.to eq(
        <<-TEXT.squish
          Mitsuki is friends with both Takayuki and Haruka, but secretly she
          has feelings for Takayuki. In high school she was a competitive swimmer.
        TEXT
      )
    end
  end

  # cassette is not recorded for site whose DNS address
  # cannot be found - it causes spec to fail on CI server
  # since HTTP request is performed again which is prohibited
  # by VCR configuration -> just stub Proxy.get response
  context 'invalid url' do
    let(:url) { 'http://foofoofoofoo.com' }
    before { allow(Proxy).to receive(:get).and_return '' }
    it { expect { call }.to raise_error EmptyContentError }
  end

  context 'unkown anime id' do
    let(:url) { 'http://anidb.net/perl-bin/animedb.pl?show=anime&aid=33911111' }
    it { expect { call }.to raise_error InvalidIdError }
  end

  context 'unkown character id' do
    let(:url) { 'http://anidb.net/perl-bin/animedb.pl?show=character&charid=33311111' }
    it { expect { call }.to raise_error InvalidIdError }
  end
end