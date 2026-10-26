# frozen_string_literal: true

class Source::Extractor
  class Furaffinity < Source::Extractor
    def self.enabled?
      # https://www.furaffinity.net/controls/settings/
      # For this strategy to work properly, in the above settings "Enable Adult Artwork" must be set to "General, Mature, Adult".
      SiteCredential.for_site("Furaffinity").present?
    end

    def image_urls
      if parsed_url.image_url?
        [parsed_url.to_s]
      else
        download_button = html_response&.css("#submission-options .button").to_a.find { |el| el.text == "Download" }
        partial_image = download_button&.[]("href")
        return [] unless partial_image.present?
        [Addressable::URI.join("https://d.furaffinity.net", partial_image).to_s].compact
      end
    end

    def tags
      tags = html_response&.css(".tags").to_a.map!(&:text).compact.uniq
      tags.map { |tag| [tag.strip, "https://www.furaffinity.net/search/@keywords #{tag.strip}"] }
    end

    def display_name
      html_response&.at(".c-usernameBlockSimple__displayName")&.text
    end

    def username
      parsed_url.username || parsed_referer&.username
    end

    def profile_url
      parsed_url.profile_url || parsed_referer&.profile_url || profile_url_from_page
    end

    def profile_url_from_page
      slug = html_response&.at(".submission-user-icon")&.parent&.[](:href)
      return unless slug.present?
      Source::URL.parse(URI.join("https://www.furaffinity.net/", slug)).profile_url
    end

    def artist_commentary_title
      html_response&.at(".submission-title")&.text&.strip
    end

    def artist_commentary_desc
      html_response&.at(".submission-description .section-body")&.to_html
    end

    def dtext_artist_commentary_desc
      DText.from_html(artist_commentary_desc, base_url: "https://www.furaffinity.net")&.strip
    end

    memoize def html_response
      if Danbooru.config.flaresolverr_url.present?
        html = flaresolverr_solution&.dig("response")
        return nil if html.blank?

        Nokogiri::HTML5.parse(html, max_tree_depth: -1)
      else
        parsed_get(page_url)
      end
    end

    # FlareSolverr is a JSON API, not an HTTP proxy. Ask it to load a FA page in a
    # browser, then reuse the clearance cookies and user-agent for CDN downloads.
    # d.furaffinity.net is also behind Cloudflare, so a/b cookies alone are not enough.
    memoize def flaresolverr_solution
      return nil if Danbooru.config.flaresolverr_url.blank?

      challenge_url = page_url.presence || "https://www.furaffinity.net/"
      cookies = [
        ["a", credentials[:cookie_a]],
        ["b", credentials[:cookie_b]],
        ["sfw", "0"],
      ].filter_map { |name, value| { name: name, value: value } if value.present? }

      response = Danbooru::Http.internal.timeout(90).post(Danbooru.config.flaresolverr_url, json: {
        cmd: "request.get",
        url: challenge_url,
        maxTimeout: 60_000,
        cookies: cookies,
      })
      payload = response.parse.deep_stringify_keys if response.status.success?
      solution = payload&.dig("solution")

      if payload.blank? || payload["status"] != "ok" || solution.blank?
        message = payload&.dig("message").presence || "HTTP #{response.status}"
        raise "FlareSolverr failed to fetch #{challenge_url} (#{message})"
      end

      solution
    end

    def http
      client = super.cookies(a: credentials[:cookie_a], b: credentials[:cookie_b], sfw: 0)
      return client if Danbooru.config.flaresolverr_url.blank?

      solution = flaresolverr_solution
      cookie_hash = Array(solution["cookies"]).to_h { |cookie| [cookie["name"], cookie["value"]] }
      client = client.cookies(cookie_hash) if cookie_hash.present?
      client = client.headers("User-Agent": solution["userAgent"]) if solution["userAgent"].present?
      client
    end
  end
end
