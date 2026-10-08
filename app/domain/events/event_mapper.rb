module Events
  # Turns a raw Billetto event hash into our attributes. Checks a few key
  # spellings since the exact response shape isn't confirmed yet.
  class EventMapper
    def self.call(raw)
      raw = raw.stringify_keys
      image = raw["image"]
      image_url = image.is_a?(Hash) ? image["url"] : image

      {
        external_id: (raw["id"] || raw["uuid"])&.to_s,
        title: raw["name"] || raw["title"],
        starts_at: raw["starts_at"] || raw["start_date"] || raw["start_at"],
        description: raw["description"] || raw["summary"],
        image_url: image_url || raw["image_url"] || raw["cover_image_url"]
      }
    end
  end
end
