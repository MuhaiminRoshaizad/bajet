import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bajet/features/ledger/domain/ledger_models.dart';
import 'package:bajet/features/plan/domain/plan_models.dart';
import 'package:bajet/features/report/data/checkin_pdf.dart';
import 'package:bajet/features/report/domain/weekly_checkin.dart';
import 'package:flutter_test/flutter_test.dart';

import 'checkin_fixtures.dart';

// A one-pixel PNG, standing in for the app icon and the coach's face.
final pixel = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==');

ByteData font(String weight) => ByteData.sublistView(File('assets/fonts/Figtree-$weight.ttf').readAsBytesSync());

int pages(WeeklyCheckin w) => checkinDocument(
      w: w,
      categories: {for (final c in categories) c.key: c},
      icon: pixel,
      coach: pixel,
      coachName: 'Bajety',
      generatedAt: DateTime(2026, 10, 25, 21, 4),
      regular: font('Regular'),
      bold: font('Bold'),
    ).document.pdfPageList.pages.length;

void main() {
  test('a quiet week fits on one page, and the file is complete', () async {
    final doc = checkinDocument(
      w: checkin(entries: week, checkins: [lastWeek]),
      categories: {for (final c in categories) c.key: c},
      icon: pixel,
      coach: pixel,
      coachName: 'Bajety',
      generatedAt: DateTime(2026, 10, 25, 21, 4),
      regular: font('Regular'),
      bold: font('Bold'),
    );
    expect(doc.document.pdfPageList.pages, hasLength(1));
    final bytes = await doc.save();
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(String.fromCharCodes(bytes.skip(bytes.length - 8)).trim(), endsWith('%%EOF'));
  });

  test('a busy week runs its entries on to more pages', () {
    final busy = [for (var n = 0; n < 70; n++) spend(d(10, 19 + n % 7), 150 + n, 'food', 'Lunch')];
    expect(pages(checkin(entries: busy, checkins: [lastWeek])), greaterThan(1));
  });

  test('a summary too long for one page moves whole blocks on, rather than failing', () {
    final bills = [for (var n = 0; n < 40; n++) RecurringItem(id: n, name: 'Bill $n', amount: 1000, categoryKey: 'bills', isIncome: false, nextDue: d(10, 26 + n % 6))];
    final long = [for (var n = 0; n < 30; n++) spend(d(10, 19 + n % 6), 300, 'food', 'A note long enough to wrap over two lines in the entries table')];
    expect(pages(checkin(entries: long, checkins: [lastWeek], recurringItems: bills)), greaterThan(1));
  });

  test('the first check-in, with no entries but its adjustment, builds too', () {
    final w = checkin(today: d(10, 18), opening: d(10, 18), entries: [spend(d(10, 18), 1230, untrackedCategoryKey, 'Starting adjustment')]);
    expect(pages(w), 1);
  });
}
