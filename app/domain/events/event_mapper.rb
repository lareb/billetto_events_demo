module Events
  # Maps a raw Billetto event hash to our attributes. A couple of
  # alternate key spellings are kept as fallbacks just in case.
  class EventMapper
    def self.call(raw)
      raw = raw.stringify_keys
      image = raw["image"]
      image_url = image.is_a?(Hash) ? image["url"] : image

      {
        external_id: (raw["id"] || raw["uuid"])&.to_s,
        title: raw["title"] || raw["name"],
        starts_at: raw["startdate"] || raw["starts_at"] || raw["start_date"],
        description: raw["description"] || raw["summary"],
        image_url: raw["image_link"] || image_url || raw["image_url"]
      }
    end
  end
end
