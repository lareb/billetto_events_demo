module Events
  # Turns a raw Billetto event hash into our attributes. Confirmed against
  # GET /api/v3/public/events on a live account: id, title, startdate,
  # description, image_link. A couple of other spellings are kept as a
  # fallback in case Billetto's API changes shape again.
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
