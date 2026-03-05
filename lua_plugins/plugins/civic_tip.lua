-- civic_tip.lua
-- Type: markdown_panel
-- Entry: get_content()
-- Returns a Markdown string with a daily rotating civic awareness tip.
-- Rotation uses day-of-year so it changes every day.

local TIPS = {
  [[## Know Your Rights
Article 27 of the **Constitution of Nepal** guarantees every citizen the right to information.
You may demand information from any public body — they must respond within **35 days**.]],

  [[## Voter Registration
You can register as a voter at your **local Ward Office** by presenting your citizenship certificate.
Check your registration status at [election.gov.np](https://www.election.gov.np).]],

  [[## Emergency Numbers
| Service    | Number |
|------------|--------|
| Police     | **100** |
| Fire       | **101** |
| Ambulance  | **102** |
| Traffic    | **103** |
| Women helpline | **1145** |
| Child helpline | **1098** |]],

  [[## Right to Information (RTI)
File an RTI request at your local **District Administration Office** or the concerned public body.
If unanswered in 35 days, appeal to the **National Information Commission** (nic.gov.np).]],

  [[## Constitution Day — Asoj 3, 2072 BS
Nepal's Constitution was promulgated on **20 September 2015**.
It is notable for being among the first constitutions in the world to explicitly
include LGBTQ+ rights (Article 12).]],

  [[## Ward Office Services
Your **Ward Office** can issue:
- Birth certificates
- Migration certificates
- Relationship certificates (नाता प्रमाणित)
- Recommendation letters for government services]],

  [[## Land Registration
Land registration (**Lalpurja**) is processed at the **District Survey Office**.
Bring the current owner's citizenship, previous ownership documents, and survey map (*napi naksha*).]],

  [[## Citizenship Certificate
A citizenship certificate can be obtained from the **District Administration Office (DAO)**.
Bring your birth certificate, parent's citizenship, and two passport-sized photos.]],

  [[## Small Claims Court
For disputes under **NPR 1,00,000**, you can file at your local Ward Office
under the **Local Government Operation Act 2074**.]],

  [[## Free Legal Aid
Citizens below the poverty line can get **free legal aid** from the
**District Legal Aid Committee** at the District Court.
Contact: 1660-01-22266 (Legal Aid Helpline)]],
}

function get_content()
  -- Rotate tips daily using day-of-year (1..366)
  local day = tonumber(os.date("%j")) or 1
  local idx  = ((day - 1) % #TIPS) + 1
  return TIPS[idx]
end
