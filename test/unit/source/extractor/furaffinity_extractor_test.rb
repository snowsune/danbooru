require "test_helper"

module Source::Tests::Extractor
  class FuraffinityExtractorTest < ActiveSupport::ExtractorTestCase
    setup { skip "Furaffinity credentials not configured" unless Source::Extractor::Furaffinity.enabled? }

    context "A furaffinity post" do
      strategy_should_work(
        "https://www.furaffinity.net/view/46821705/",
        image_urls: ["https://d.furaffinity.net/art/iwbitu/1650222955/1650222955.iwbitu_yubi.jpg"],
        profile_url: "https://www.furaffinity.net/user/iwbitu",
        page_url: "https://www.furaffinity.net/view/46821705",
        display_name: "iwbitu",
        username: nil,
        artist_commentary_title: "Yubi",
        artist_commentary_desc: /little gift doodle for/,
      )
    end

    context "A furaffinity image" do
      strategy_should_work(
        "https://d.furaffinity.net/art/iwbitu/1650222955/1650222955.iwbitu_yubi.jpg",
        image_urls: ["https://d.furaffinity.net/art/iwbitu/1650222955/1650222955.iwbitu_yubi.jpg"],
        profile_url: "https://www.furaffinity.net/user/iwbitu",
        display_name: nil,
        username: "iwbitu",
        page_url: nil,
        artist_commentary_title: nil,
      )
    end

    context "An adult age-restricted furaffinity post" do
      strategy_should_work(
        "https://www.furaffinity.net/view/46590097/",
        image_urls: ["https://d.furaffinity.net/art/iwbitu/1648803766/1648803766.iwbitu_nyopu_tori.jpg"],
        profile_url: "https://www.furaffinity.net/user/iwbitu",
        page_url: "https://www.furaffinity.net/view/46590097",
        display_name: "iwbitu",
        username: nil,
        tags: [],
        artist_commentary_title: "Nyopu and Tori",
        artist_commentary_desc: /UwU/,
      )
    end

    context "A deleted or non-existing furaffinity post" do
      strategy_should_work("https://www.furaffinity.net/view/3404111", deleted: true, profile_url: nil)
    end

    context "A furaffinity post with non-ascii image url" do
      strategy_should_work(
        "https://www.furaffinity.net/view/20762907/",
        image_urls: ["https://d.furaffinity.net/art/fhedge/1470365580/1470365580.fhedge_ミストランサーまとめアートボード_1.jpg"],
      )
    end

    context "A furaffinity post with relative URLs in the commentary" do
      strategy_should_work(
        "https://www.furaffinity.net/view/24228367",
        image_urls: ["https://d.furaffinity.net/art/mazen234/1500679554/1500679554.mazen234_foxgirl.png"],
        display_name: "mazen234",
        username: nil,
        artist_commentary_title: "Miko Sleeping at the beach~",
        dtext_artist_commentary_desc: <<~EOS.chomp,
          Mikey went to get some things from the shop, so Miko probably took some time to herself to rest! Not saying Mikey might be a handful sometimes :P

          Glad you loved this piece, Sheep! ^_^

          Miko @ The Lovely "silentsheep SilentSheep":[https://www.furaffinity.net/user/silentsheep]

          Art @ CuteSexyRoButts from DeviantArt
        EOS
      )
    end
  end

  class FuraffinityFlareSolverrTest < ActiveSupport::TestCase
    setup do
      Danbooru.config.stubs(:flaresolverr_url).returns("http://flaresolverr:8191/v1")
    end

    should "read the download URL from the page FlareSolverr returns" do
      html = <<~HTML
        <div id="submission-options">
          <a class="button standard mobile-fix" href="//d.furaffinity.net/art/tershaserou/1792073798/1792073798.tershaserou_example.png">Download</a>
        </div>
      HTML
      stub_flaresolverr(status: "ok", solution: { response: html, status: 200 })

      strategy = Source::Extractor::Furaffinity.new("https://www.furaffinity.net/view/66707672/")

      assert_equal(
        ["https://d.furaffinity.net/art/tershaserou/1792073798/1792073798.tershaserou_example.png"],
        strategy.image_urls,
      )
    end

    should "report a FlareSolverr error instead of an empty page" do
      stub_flaresolverr(status: "error", message: "Cloudflare challenge failed")
      strategy = Source::Extractor::Furaffinity.new("https://www.furaffinity.net/view/66707672/")

      error = assert_raises(RuntimeError) { strategy.image_urls }
      assert_match("FlareSolverr failed to fetch https://www.furaffinity.net/view/66707672", error.message)
      assert_match("Cloudflare challenge failed", error.message)
    end

    def stub_flaresolverr(payload)
      response = HTTP::Response.new(
        status: 200,
        version: "1.1",
        headers: { "Content-Type" => "application/json" },
        body: payload.to_json,
        request: HTTP::Request.new(verb: :post, uri: "http://flaresolverr:8191/v1"),
      )
      Danbooru::Http.any_instance.stubs(:post).returns(response)
    end
  end
end
