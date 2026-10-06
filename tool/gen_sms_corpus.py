#!/usr/bin/env python3
"""Generates the synthetic SMS corpus used by the capture test suite.

The corpus is **entirely fabricated** — no real message, sender or account ever
enters this repository. Bank sender IDs and the shape of Indian transaction
alerts are public knowledge; the amounts, account tails and people are invented.

Running this again with the same seed produces byte-identical output, so the
accuracy numbers in `docs/06-SMS-PARSING.md` §10 are reproducible.

    python3 tool/gen_sms_corpus.py

Writes test/fixtures/sms/corpus200.json (T-113's 200-sample accuracy gate) and
test/fixtures/sms/noise60.json (the zero-false-positive gate).
"""

import datetime as dt
import json
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "test" / "fixtures" / "sms"

SEED = 20261007
rng = random.Random(SEED)

CARRIERS = ["VM", "AD", "AX", "VK", "TM", "BM"]

BANKS = [
    ("HDFCBK", "HDFC Bank"),
    ("ICICIB", "ICICI Bank"),
    ("SBIINB", "SBI"),
    ("AXISBK", "Axis Bank"),
    ("KOTAKB", "Kotak Mahindra Bank"),
    ("PNBSMS", "Punjab National Bank"),
    ("BOBSMS", "Bank of Baroda"),
    ("CANBNK", "Canara Bank"),
    ("UNIONB", "Union Bank of India"),
    ("IDFCBK", "IDFC FIRST Bank"),
    ("YESBNK", "Yes Bank"),
    ("INDBNK", "Indian Bank"),
    ("BANDHN", "Bandhan Bank"),
    ("FEDBNK", "Federal Bank"),
]

# (rupees, printed form). Indian grouping where a real alert would use it.
AMOUNTS = [
    (75.50, "75.50"),
    (150, "150"),
    (199, "199.00"),
    (250.50, "250.50"),
    (320, "320.00"),
    (450, "450"),
    (500, "500.00"),
    (899, "899.00"),
    (999.99, "999.99"),
    (1200, "1200.00"),
    (1240, "1,240.00"),
    (1499, "1,499.00"),
    (2499, "2,499.00"),
    (4500, "4,500.00"),
    (8000, "8,000.00"),
    (12500, "12,500.00"),
    (25000, "25,000.00"),
    (45000, "45,000.00"),
    (120000, "1,20,000.00"),
    (124000, "1,24,000.00"),
    (150000, "1,50,000.00"),
    (200000, "2,00,000.00"),
]

UPI_MERCHANTS = [
    ("Swiggy", "swiggy@ybl"),
    ("Zomato", "zomato@ybl"),
    ("BigBasket", "bigbasket@ybl"),
    ("Blinkit", "blinkit@ybl"),
    ("Zepto", "zepto@ybl"),
    ("Rapido", "rapido@ybl"),
    ("Netflix", "netflix@ybl"),
    ("Spotify", "spotify@ybl"),
    ("PhonePe", "phonepe@ybl"),
    ("Paytm", "paytm@paytm"),
    ("Jio", "jio@ybl"),
    ("Airtel", "airtel@ybl"),
]

CARD_MERCHANTS = [
    "DMart",
    "Myntra",
    "Decathlon",
    "Apollo",
    "BookMyShow",
    "PVR",
    "Pantaloons",
    "Bata",
    "Nykaa",
    "Starbucks",
    "KFC",
]

PERSONS = ["Ramesh Kumar", "Deepa Sharma", "Amit Das", "Priya Sen", "Suman Ghosh"]

MONTHS = {
    1: "JAN", 2: "FEB", 3: "MAR", 4: "APR", 5: "MAY", 6: "JUN",
    7: "JUL", 8: "AUG", 9: "SEP", 10: "OCT", 11: "NOV", 12: "DEC",
}

BN_DIGITS = "০১২৩৪৫৬৭৮৯"


def bn(number_str: str) -> str:
    return "".join(BN_DIGITS[int(c)] if c.isdigit() else c for c in number_str)


def iso(day: dt.date) -> str:
    return day.isoformat()


def sms_at(day: dt.date) -> str:
    """18:30 IST on the day of the transaction, expressed in UTC."""
    return f"{day.isoformat()}T13:00:00Z"


def sender() -> str:
    code, _ = rng.choice(BANKS)
    return f"{rng.choice(CARRIERS)}-{code}"


def bank() -> tuple[str, str]:
    return rng.choice(BANKS)


def acct4() -> str:
    return f"{rng.randint(1000, 9999)}"


def acct_full(tail: str) -> str:
    return f"{rng.randint(100, 999)}{rng.randint(100, 999)}{tail[:3]}"


def ref() -> str:
    return str(rng.randint(10**9, 10**12))


def balance() -> str:
    if rng.random() < 0.5:
        return f"{rng.randint(1, 9)},{rng.randint(100, 999):03d}.{rng.randint(0, 99):02d}"
    return f"{rng.randint(1000, 99999)}.{rng.randint(0, 99):02d}"


def day_in_range() -> dt.date:
    start = dt.date(2026, 8, 1)
    return start + dt.timedelta(days=rng.randint(0, 66))


def date_strings(day: dt.date) -> dict[str, str]:
    return {
        "dmy2": f"{day.day:02d}-{day.month:02d}-{day.year % 100:02d}",
        "dmy4": f"{day.day:02d}-{day.month:02d}-{day.year}",
        "dmmmy": f"{day.day:02d}-{MONTHS[day.month]}-{day.year}",
        "compact": f"{day.day:02d}{MONTHS[day.month]}{day.year % 100:02d}",
    }


def tx(note, body, day, *, direction, amount, merchant, mode, last4):
    return {
        "note": note,
        "sender": sender(),
        "body": body,
        "smsAtIso": sms_at(day),
        "expect": {
            "direction": direction,
            "amountPaise": int(round(amount * 100)),
            "merchant": merchant,
            "mode": mode,
            "accountLast4": last4,
            "dateIso": iso(day),
        },
    }


def generate_transactions(count: int) -> list[dict]:
    out: list[dict] = []
    builders = [
        "upi_vpa", "upi_named", "inr_at", "card_spent", "card_debited",
        "atm", "neft_person", "salary", "fd_interest", "refund",
        "credit_vpa", "wallet", "bengali", "hindi", "plain_account",
        "card_short", "date_mmm", "date_compact", "rent_lakh", "towards",
    ]

    while len(out) < count:
        kind = builders[len(out) % len(builders)]
        day = day_in_range()
        d = date_strings(day)
        rupees, printed = rng.choice(AMOUNTS)
        tail = acct4()
        bal = balance()

        if kind == "upi_vpa":
            display, vpa = rng.choice(UPI_MERCHANTS)
            body = (
                f"Rs.{printed} debited from A/c XX{tail} on {d['dmy2']} to VPA "
                f"{vpa} (UPI Ref {ref()}). Avl Bal Rs.{bal}"
            )
            out.append(tx("UPI debit to a merchant VPA", body, day,
                          direction="expense", amount=rupees, merchant=display,
                          mode="upi", last4=tail))

        elif kind == "upi_named":
            display, _ = rng.choice(UPI_MERCHANTS)
            body = (
                f"Rs.{printed} debited from A/c XX{tail} on {d['dmy2']} to "
                f"{display} via UPI (Ref {ref()}). Avl Bal Rs.{bal}"
            )
            out.append(tx("UPI debit naming the merchant", body, day,
                          direction="expense", amount=rupees, merchant=display,
                          mode="upi", last4=tail))

        elif kind == "inr_at":
            display = rng.choice(CARD_MERCHANTS)
            body = (
                f"INR {printed} debited from A/c XX{tail} on {d['dmy4']} at "
                f"{display}. Avl Bal INR {bal}"
            )
            out.append(tx("card-style spend written with INR", body, day,
                          direction="expense", amount=rupees, merchant=display,
                          mode="other", last4=tail))

        elif kind == "card_spent":
            _, name = bank()
            display = rng.choice(CARD_MERCHANTS)
            body = (
                f"Rs.{printed} spent on your {name} Card ending {tail} at "
                f"{display} on {d['dmy2']}."
            )
            out.append(tx("card spend with 'ending NNNN'", body, day,
                          direction="expense", amount=rupees, merchant=display,
                          mode="card", last4=tail))

        elif kind == "card_debited":
            _, name = bank()
            display = rng.choice(CARD_MERCHANTS)
            body = (
                f"Your {name} Credit Card XX{tail} has been debited with "
                f"Rs.{printed} on {d['dmy2']} at {display}. Avl limit Rs.{bal}"
            )
            out.append(tx("'Credit Card ... has been debited' must stay an expense",
                          body, day, direction="expense", amount=rupees,
                          merchant=display, mode="card", last4=tail))

        elif kind == "atm":
            body = (
                f"Rs.{printed} withdrawn from A/c XX{tail} at ATM on "
                f"{d['dmy2']}. Avl Bal Rs.{bal}"
            )
            out.append(tx("ATM withdrawal — no merchant", body, day,
                          direction="expense", amount=rupees, merchant=None,
                          mode="cash", last4=tail))

        elif kind == "neft_person":
            person = rng.choice(PERSONS)
            body = (
                f"Rs.{printed} debited from A/c XX{tail} on {d['dmy2']} to "
                f"{person} via NEFT. Avl Bal Rs.{bal}"
            )
            out.append(tx("NEFT transfer to a person", body, day,
                          direction="expense", amount=rupees, merchant=person,
                          mode="netbanking", last4=tail))

        elif kind == "salary":
            body = (
                f"Rs.{printed} credited to your A/c XX{tail} on {d['dmy2']} "
                f"by salary transfer. Avl Bal Rs.{bal}"
            )
            out.append(tx("salary credit", body, day, direction="income",
                          amount=rupees, merchant=None, mode="other",
                          last4=tail))

        elif kind == "fd_interest":
            body = (
                f"INR {printed} credited to A/c XX{tail} on {d['dmy4']} "
                f"towards FD Interest. Avl Bal INR {bal}"
            )
            out.append(tx("FD interest credit", body, day, direction="income",
                          amount=rupees, merchant="FD Interest", mode="other",
                          last4=tail))

        elif kind == "refund":
            display, _ = rng.choice(UPI_MERCHANTS)
            body = (
                f"Rs.{printed} credited to A/c XX{tail} on {d['dmy2']} from "
                f"{display} Refund. Avl Bal Rs.{bal}"
            )
            out.append(tx("refund credit from a merchant", body, day,
                          direction="income", amount=rupees, merchant=display,
                          mode="other", last4=tail))

        elif kind == "credit_vpa":
            display, vpa = rng.choice(UPI_MERCHANTS)
            body = (
                f"Rs.{printed} credited to A/c XX{tail} on {d['dmy2']} from "
                f"VPA {vpa} (UPI Ref {ref()}). Avl Bal Rs.{bal}"
            )
            out.append(tx("UPI credit from a merchant VPA", body, day,
                          direction="income", amount=rupees, merchant=display,
                          mode="upi", last4=tail))

        elif kind == "wallet":
            body = (
                f"Rs.{printed} debited from Paytm Wallet on {d['dmy2']} for "
                f"Mobile Recharge. Avl Bal Rs.{bal}"
            )
            out.append(tx("wallet debit for a recharge", body, day,
                          direction="expense", amount=rupees, merchant="Paytm",
                          mode="wallet", last4=None))

        elif kind == "bengali":
            body = f"আপনার অ্যাকাউন্ট থেকে ৳ {bn(printed)} ডেবিট হয়েছে।"
            out.append(tx("Bengali alert with Bengali numerals", body, day,
                          direction="expense", amount=rupees, merchant=None,
                          mode="other", last4=None))

        elif kind == "hindi":
            body = f"आपके खाते से ₹{printed} डेबिट हुए हैं।"
            out.append(tx("Hindi alert", body, day, direction="expense",
                          amount=rupees, merchant=None, mode="other",
                          last4=None))

        elif kind == "plain_account":
            full = acct_full(tail)
            body = (
                f"Rs.{printed} debited from your account {full} on "
                f"{d['dmy2']} to Bajaj Finserv EMI. Avl Bal Rs.{bal}"
            )
            out.append(tx("unmasked account number, EMI merchant", body, day,
                          direction="expense", amount=rupees,
                          merchant="Bajaj Finserv", mode="other", last4=full[-4:]))

        elif kind == "card_short":
            display = rng.choice(CARD_MERCHANTS)
            body = (
                f"Rs.{printed} spent on your card ending {tail} at {display} "
                f"on {d['dmy2']}."
            )
            out.append(tx("short card phrasing", body, day,
                          direction="expense", amount=rupees, merchant=display,
                          mode="card", last4=tail))

        elif kind == "date_mmm":
            display, vpa = rng.choice(UPI_MERCHANTS)
            body = (
                f"Rs.{printed} debited from A/c XX{tail} on {d['dmmmy']} to "
                f"VPA {vpa}. Avl Bal Rs.{bal}"
            )
            out.append(tx("dd-MMM-yyyy date", body, day, direction="expense",
                          amount=rupees, merchant=display, mode="upi",
                          last4=tail))

        elif kind == "date_compact":
            display = rng.choice(CARD_MERCHANTS)
            body = (
                f"Rs.{printed} debited from A/c XX{tail} on {d['compact']} to "
                f"{display}. Avl Bal Rs.{bal}"
            )
            out.append(tx("07OCT26-style compact date", body, day,
                          direction="expense", amount=rupees, merchant=display,
                          mode="other", last4=tail))

        elif kind == "rent_lakh":
            body = (
                f"Rs {printed} debited from A/c XX{tail} on {d['dmy2']} "
                f"towards House Rent. Avl Bal Rs {bal}"
            )
            out.append(tx("rent with lakh-grouped amount", body, day,
                          direction="expense", amount=rupees,
                          merchant="House Rent", mode="other", last4=tail))

        else:  # towards
            display = rng.choice(CARD_MERCHANTS)
            body = (
                f"Rs.{printed} debited from A/c XX{tail} on {d['dmy2']} "
                f"towards {display}. Avl Bal Rs.{bal}"
            )
            out.append(tx("'towards <merchant>' phrasing", body, day,
                          direction="expense", amount=rupees, merchant=display,
                          mode="other", last4=tail))

    return out[:count]


NOISE_TEMPLATES = [
    ("otp_with_amount", "otp"),
    ("balance_only", "balance_only"),
    ("cashback_offer", "non_transaction"),
    ("statement_ready", "non_transaction"),
    ("kyc_nudge", "non_transaction"),
    ("preapproved_loan", "non_transaction"),
    ("personal_number", "unknown_sender"),
    ("missed_call", "non_transaction"),
    ("future_mandate", "non_transaction"),
    ("order_shipped", "no_signal"),
    ("promo_credited", "non_transaction"),
    ("unknown_sender_code", "unknown_sender"),
    ("otp_with_account", "otp"),
    ("scratch_card", "non_transaction"),
    ("insurance_offer", "non_transaction"),
    ("bill_reminder", "non_transaction"),
]


def generate_noise(count: int) -> list[dict]:
    out: list[dict] = []
    while len(out) < count:
        kind, expectation = NOISE_TEMPLATES[len(out) % len(NOISE_TEMPLATES)]
        day = day_in_range()
        d = date_strings(day)
        code, name = bank()
        tail = acct4()
        rupees, printed = rng.choice(AMOUNTS)

        if kind == "otp_with_amount":
            body = f"OTP {rng.randint(1000, 999999)} for your txn of Rs {printed} at Myntra. Do not share."
            s = sender()
        elif kind == "balance_only":
            body = f"Your A/c XX{tail} Avl Bal is Rs.{balance()} as on {d['dmy2']}."
            s = sender()
        elif kind == "cashback_offer":
            body = f"Get Rs.{printed} cashback on your next 3 transactions. Offer valid till {d['dmy2']}. T&C apply."
            s = sender()
        elif kind == "statement_ready":
            body = (
                f"Your {name} Credit Card statement for {d['dmmmy'][3:]} is ready. "
                f"Total due Rs {printed}. Minimum due Rs 620."
            )
            s = sender()
        elif kind == "kyc_nudge":
            body = "Dear Customer, complete your KYC to continue using your account. Visit branch or click here: bit.ly/xyz"
            s = sender()
        elif kind == "preapproved_loan":
            body = f"Pre-approved personal loan of Rs {printed} at 10.5%. Apply now! Offer expires soon."
            s = f"{rng.choice(CARRIERS)}-BAJAJF"
        elif kind == "personal_number":
            body = f"Bhai {rupees:.0f} taka pathiye de, kal ferot debo."
            s = f"+9198{rng.randint(10000000, 99999999)}"
        elif kind == "missed_call":
            body = f"Missed call alert from 98{rng.randint(10000000, 99999999)}. Your credit card bill due is Rs {printed}."
            s = sender()
        elif kind == "future_mandate":
            body = f"Rs {printed} will be debited on {d['dmy2']} as per e-mandate for Netflix."
            s = sender()
        elif kind == "order_shipped":
            body = f"Your order of Rs {printed} has been shipped. Track at bit.ly/x"
            s = f"{rng.choice(CARRIERS)}-AMAZONP"
        elif kind == "promo_credited":
            body = f"Congratulations! Rs {printed} credited as part of our welcome offer. Apply now."
            s = sender()
        elif kind == "unknown_sender_code":
            body = f"Rs.{printed} debited from A/c XX{tail} on {d['dmy2']}. Avl Bal Rs.{balance()}"
            s = f"DM-{code}SPAM"
        elif kind == "otp_with_account":
            body = f"{rng.randint(100000, 999999)} is the verification code for your A/c XX{tail}. Never share it."
            s = sender()
        elif kind == "scratch_card":
            body = f"You have won a scratch card worth Rs {printed}! Click here to claim. T&C apply."
            s = sender()
        elif kind == "insurance_offer":
            body = f"Protect your family with our insurance plan at just Rs 499/month. Apply now."
            s = sender()
        else:  # bill_reminder
            body = f"Your electricity bill of Rs {printed} is due on {d['dmy2']}. Pay now to avoid disconnection."
            s = sender()

        out.append({
            "note": kind,
            "sender": s,
            "body": body,
            "smsAtIso": sms_at(day),
            "expectReject": expectation,
        })
    return out[:count]


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    corpus = generate_transactions(200)
    noise = generate_noise(60)

    (OUT_DIR / "corpus200.json").write_text(
        json.dumps(corpus, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    (OUT_DIR / "noise60.json").write_text(
        json.dumps(noise, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )

    print(f"wrote {len(corpus)} transactions → corpus200.json")
    print(f"wrote {len(noise)} noise messages → noise60.json")


if __name__ == "__main__":
    main()
