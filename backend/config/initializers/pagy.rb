require "pagy/extras/overflow"

# A page past the end returns an empty page (with correct totals) instead of raising.
Pagy::DEFAULT[:overflow] = :empty_page
