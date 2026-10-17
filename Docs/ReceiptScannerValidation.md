# Receipt OCR and close-focus validation

Validated on 16 October 2026 with the iPhone 17 simulator running iOS 27. The supplied receipt-photo tests explicitly disable Apple Intelligence. The scanner still offers its existing optional on-device amount-selection fallback in normal use when that model is available.

## Supplied photo results

| Test fixture | OCR total | Suggested category | Printed date | Note/header behavior |
| --- | --- | --- | --- | --- |
| restaurant-payable.jpeg | ₹8,299.00 | Restaurants | 26 February 2022 | Header cropped away; uses “Scanned Receipt” |
| idli-grand-total.jpeg | ₹550.00 | Restaurants | 21 April 2026 | Brahmins Thatte Idli |
| pista-house.jpg | ₹600.00 | Restaurants | 9 June 2020 | Pista House |
| hospitality-dining.jpg | ₹12,569.00 | Restaurants | 26 December 2025 | M/S G.N Hospitality |
| covered-header.jpg | ₹15,809.00 | Restaurants | Unreadable; review required | Does not turn a partial header or dish into a business name |
| us-ebt-deli.jpg | $26.48 | Restaurants | 24 July 2020 | Reads the deli header; rejects the $244.28 available balance |
| sideways-rounded.jpg | ₹1,470.00 | Restaurants | Not visible; review required | Rotates the image; chooses the rounded bill total over ₹1,470.06 |
| obscured-tax-table.jpg | Unfilled; review required | None | Unreadable | Does not save a long reference misread as a total |
| clothing-discount.jpg | ₹6,755.00 | Clothing | 1 February 2026 | Reads Charms Collections; selects the discounted net amount |

All eight legible final amounts were extracted correctly in this run. The ninth image was deliberately left unresolved. Six visible dates passed day/month checks. Missing names/dates remain reviewable rather than being invented.

Shop-name transcription is not perfect: the deli name was read as “Gourmer” rather than “Gourmet”, and the clothing receipt's “PVT.” was read as “PYT.” These spelling issues remain visible for editing; no brand-name correction is guessed.

## Changes

- Final payable, net amount, and rounded-total labels outrank gross/bill totals. OCR-separated decimal digits such as `600. 00` are handled.
- Tax, discounts, available balances, identifiers, and long unformatted references are excluded from amount selection. A single unlabeled item price is insufficient to establish a final total.
- Same-row geometry links split labels and amounts, including values which sort before their labels on skewed paper. OCR row ordering now uses explicit rows rather than a non-transitive comparison.
- Sideways text triggers a bounded rotation retry. Uncertain photographed receipts get a perspective-corrected/contrast-enhanced OCR retry; payment screenshots retain their original layout. Different image coordinate spaces are never merged. Conflicting strong totals require review.
- Indian tax markers provide a currency clue when a receipt omits the rupee symbol. Unambiguous date components override the app currency's usual day/month ordering.
- Category suggestions use both merchant and purchased-item words, prefer specific existing categories, support a general Food fallback, and leave ties or unsupported cases unselected. Hidden categories and the wrong transaction type are excluded. A merchant signal such as a supermarket or delivery provider takes precedence over generic food items.
- Whole-word payment-provider detection avoids mistaking an address such as “Bhupindra Road” for a UPI screenshot. Payment-recipient prefixes also use word boundaries, so `TOTAL` is not treated as `To`.
- Tender matching ignores “Cash customer” and zero cash amounts, preventing an otherwise credit-paid clothing receipt from being assigned to Cash.

## Additional coverage

Four generated receipt images exercise a grocery basket (₹360), a US café receipt with tax and tip ($19.20), fuel with a separate unit price (₹1,850), and pharmacy items with tax (₹47.25). All four amount/category checks pass without Apple Intelligence. These generated fixtures are separate from the nine original photographs.

The existing provider tests also remain in the run: Google Pay, PhonePe, and Paytm layouts, dark/light appearances, incoming money, pending/failed status, account/reference exclusions, Indian grouping, rupee-glyph repair, and merchant/date regressions.

The original validation run completed with **27 tests passed, 1 skipped, 0 failures** across `ReceiptAmountParserTests` and `ReceiptPhotoRegressionTests`. The skipped test requires an available Apple Intelligence model; its successful-model behavior was not validated on this simulator. Build and `git diff --check` passed.

Local results: `/private/tmp/spendy-receipt-verified-20261016.xcresult`. The nine photos were subsequently removed from the repository at the user's request. Photo validation is now optional: set `SPENDY_RECEIPT_FIXTURES_DIR` in the test runner's environment to an external folder containing the filenames in the table above. Without that setting, only the photo-dependent test is skipped; generated-receipt and text/parser checks remain active. No receipt image files are required in the repository or bundled into the test target.

A separate macOS Vision diagnostic encountered host OCR runtime errors on some images. Those diagnostics are not used as an accuracy baseline against the iOS results above.

## Camera changes and physical-device check

The camera now prefers a virtual triple/dual-wide camera when available, starts at the main lens's field of view, permits automatic lens switching, enables continuous autofocus with a supported near-range hint, and supports tapping the receipt to focus/expose at that location. Photo capture prioritizes quality.

These changes compile, but simulator testing cannot validate optics, macro switching, or focus sharpness. On a physical iPhone:

1. Open the receipt camera and slowly move a receipt from approximately 30 cm toward the camera. Check that the text settles into focus and that lens switching does not get stuck.
2. Tap small printed text near the center and toward a corner; confirm focus follows the tapped point and the photo stays sharp.
3. Repeat in dim light, then move back to a normal distance. Check that autofocus can recover.
4. On a phone without close-focus/macro hardware, verify ordinary autofocus and tap-to-focus; objects inside the physical lens's minimum focus distance will still require more distance.
5. Check capture, close, and photo-library selection still work with the existing camera layout.

Apple references: [minimum focus distance](https://developer.apple.com/documentation/avfoundation/avcapturedevice/minimumfocusdistance), [automatic camera switching](https://developer.apple.com/documentation/avfoundation/avcapturedevice/primaryconstituentdeviceswitchingbehavior-swift.enum/auto), [focus-range hints](https://developer.apple.com/documentation/avfoundation/avcapturedevice/autofocusrangerestriction-swift.enum), [preview-point conversion](https://developer.apple.com/documentation/avfoundation/avcapturevideopreviewlayer/capturedevicepointconverted(fromlayerpoint:)).
