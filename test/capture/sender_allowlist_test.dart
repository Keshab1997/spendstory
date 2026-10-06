import 'package:flutter_test/flutter_test.dart';
import 'package:spendstory/capture/sender_allowlist.dart';

void main() {
  group('SenderAllowlist.normalize', () {
    test('strips the carrier prefix', () {
      expect(SenderAllowlist.normalize('VM-HDFCBK'), 'HDFCBK');
      expect(SenderAllowlist.normalize('AD-ICICIB'), 'ICICIB');
      expect(SenderAllowlist.normalize('AX-SBIINB'), 'SBIINB');
      expect(SenderAllowlist.normalize('VK-KOTAKB'), 'KOTAKB');
      expect(SenderAllowlist.normalize('TM-BOBSMS'), 'BOBSMS');
      expect(SenderAllowlist.normalize('BM-PNBSMS'), 'PNBSMS');
    });

    test('is case-insensitive and trims whitespace', () {
      expect(SenderAllowlist.normalize('  vm-hdfcbk  '), 'HDFCBK');
      expect(SenderAllowlist.normalize('icicib'), 'ICICIB');
    });

    test('strips a trailing service suffix', () {
      expect(SenderAllowlist.normalize('HDFCBK-S'), 'HDFCBK');
      expect(SenderAllowlist.normalize('ICICIB-1'), 'ICICIB');
    });

    test('tolerates underscore separators', () {
      expect(SenderAllowlist.normalize('VM_HDFCBK'), 'HDFCBK');
    });

    test('leaves an unrecognised sender as-is', () {
      expect(SenderAllowlist.normalize('+919876543210'), '+919876543210');
    });
  });

  group('SenderAllowlist.lookup', () {
    final allowlist = SenderAllowlist();

    test('resolves every carrier variant of a known bank', () {
      for (final sender in ['VM-HDFCBK', 'AD-HDFCBK', 'hdfcbk', 'HDFCBK-S']) {
        final entry = allowlist.lookup(sender);
        expect(entry, isNotNull, reason: sender);
        expect(entry!.parserKey, 'hdfc');
        expect(entry.bankName, 'HDFC Bank');
      }
    });

    test('knows the card, wallet and NBFC senders', () {
      expect(allowlist.lookup('VM-HDFCCC')?.parserKey, 'hdfc_card');
      expect(allowlist.lookup('AD-ICICIC')?.parserKey, 'icici_card');
      expect(allowlist.lookup('VM-CRED')?.bankName, 'CRED');
    });

    test('rejects a personal number, a short code and garbage', () {
      expect(allowlist.lookup('+919876543210'), isNull);
      expect(allowlist.lookup('9876543210'), isNull);
      expect(allowlist.lookup(''), isNull);
      expect(allowlist.lookup('DM-SOMESPAM'), isNull);
    });

    test('the allowlist covers the banks promised in the spec', () {
      // docs/06-SMS-PARSING.md §3 — 32 bank senders + card/wallet senders.
      final bankSenders = SenderAllowlist.defaultEntries
          .where(
            (e) => !e.parserKey.contains('card') && !e.parserKey.contains('_'),
          )
          .length;
      expect(SenderAllowlist.defaultEntries.length, greaterThanOrEqualTo(50));
      expect(bankSenders, greaterThanOrEqualTo(30));
    });
  });
}
