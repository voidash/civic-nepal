-- nepali_holidays.lua
-- Type: calendar_inject
-- Entry: get_events(year, month)
-- Returns a list of fixed Nepali public holidays for the given Gregorian month.
--
-- Each entry: { day, title, description, color }
-- color is a hex string; red is used for public holidays.

local HOLIDAYS = {
  -- Gregorian month 1 (January)
  { month = 1,  day = 11, title = "Prithvi Jayanti (पृथ्वी जयन्ती)",        description = "National Unity Day",     color = "#E53935" },
  -- February
  { month = 2,  day = 19, title = "Democracy Day (प्रजातन्त्र दिवस)",       description = "Constitution public holiday", color = "#E53935" },
  -- March
  { month = 3,  day = 8,  title = "Women's Day (महिला दिवस)",               description = "International Women's Day",  color = "#8E24AA" },
  -- April
  { month = 4,  day = 14, title = "Nepali New Year (नयाँ वर्ष)",            description = "Baisakh 1 — national holiday", color = "#E53935" },
  { month = 4,  day = 29, title = "Republic Day Eve",                         description = "Preparation day",            color = "#1E88E5" },
  -- May
  { month = 5,  day = 28, title = "Republic Day (गणतन्त्र दिवस)",          description = "Jestha 15 — founding of republic", color = "#E53935" },
  -- August
  { month = 8,  day = 20, title = "Janai Purnima (जनै पूर्णिमा)",          description = "Sacred thread festival",      color = "#FB8C00" },
  { month = 8,  day = 29, title = "Constitution Day (संविधान दिवस)",       description = "Asoj 3 — promulgation day",   color = "#E53935" },
  -- September
  { month = 9,  day = 20, title = "Constitution Day (observed)",             description = "Alternate Gregorian date",    color = "#E53935" },
  -- October
  { month = 10, day = 2,  title = "Gandhi Jayanti",                          description = "International Non-Violence Day", color = "#43A047" },
  -- November
  { month = 11, day = 8,  title = "Deepawali / Laxmi Puja (लक्ष्मी पूजा)", description = "Festival of lights",         color = "#FFB300" },
  -- December
  { month = 12, day = 28, title = "King Prithvi Narayan Birth Anniversary",  description = "Poush 11",                    color = "#1E88E5" },
}

function get_events(year, month)
  local results = {}
  for _, h in ipairs(HOLIDAYS) do
    if h.month == month then
      results[#results + 1] = {
        day         = h.day,
        title       = h.title,
        description = h.description,
        color       = h.color,
      }
    end
  end
  return results
end
