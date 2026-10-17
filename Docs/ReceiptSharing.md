# Open a shared receipt in Spendy

In Photos or another app that shares an image file, choose Share → Spendy. Spendy launches, imports the image locally and opens the existing Home receipt review. Its existing OCR, field editors, full transaction editor and Add transaction button handle the rest. There is no separate Share extension or alternate review design. Close leaves the ledger unchanged; Add saves through the normal transaction flow.

The app declares `public.image` in `CFBundleDocumentTypes` with the Viewer role and supports opening documents in place. SwiftUI's `onOpenURL` receives the file, security-scoped and coordinated reading loads a bounded thumbnail, and MainTabView presents the same ReceiptScannerSheet used by Home. The original image is never modified. Images above 20 MB are rejected and decoded images are downsampled to a maximum dimension of 2400 pixels.

This uses Apple's supported document-opening path rather than launching the app from an extension with a runtime workaround. The source app controls which share destinations are offered. Photos has been verified in the simulator; Google Pay and PhonePe must still be checked on an iPhone. Plain text, links and PDFs are not registered as receipt documents. The existing camera shortcut still opens Home's camera directly.

Receipts added using the superseded extension build remain supported by the legacy queued-receipt importer. New image shares go directly to the app's review and ledger.

Tests cover image decoding, original-file preservation, bounds, invalid inputs and file URL routing. An opt-in Photos test uses a generated Corner Cafe / INR 135 completed-payment image as the latest Photos item. Set `TEST_RUNNER_SPENDY_SHARE_PHOTO_TEST=1` to run it. No receipt images are stored in the repository.
