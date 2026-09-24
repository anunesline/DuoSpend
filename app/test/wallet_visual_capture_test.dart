import 'dart:io';
import 'dart:ui' as ui;
import 'package:app/features/home/data/models/wallet_model.dart';
import 'package:app/features/home/data/models/credit_card_model.dart';
import 'package:app/features/home/data/models/credit_card_invoice_model.dart';
import 'package:app/features/transactions/data/models/transaction_model.dart';
import 'package:app/features/wallet/presentation/controllers/wallet_details_controller.dart';
import 'package:app/features/wallet/presentation/pages/wallet_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
 testWidgets('capture actual wallet widget', (tester) async {
  await initializeDateFormatting('pt_BR');
  final font = File('/workspace/scratch/8d8b125faa5a/runtime/flutter/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf');
  if (font.existsSync()) {
   final loader = FontLoader('Roboto')..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync())));
   await loader.load();
  }
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(853, 1844);
  tester.view.padding = const FakeViewPadding(top: 60, bottom: 40);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  final now = DateTime(2026,5,10);
  final wallet = WalletModel(id: 'w', name: 'Banco Inter', balance: 3287.45);
  TransactionModel tx(String id,double value,String type,int day,String status) => TransactionModel(
   id:id,description:id,value:value,type:type,date:DateTime(2026,5,day),walletId:'w',category:'Casa',subcategory:'Outros',financialStatus:status);
  final controller = WalletDetailsController(wallet:wallet, clock:()=>now, loader:(_) async=>WalletDetailsData(
   wallet:wallet, transactions:[tx('Aluguel',1850,'expense',15,'pending'),tx('Salário',6250,'income',17,'pending'),tx('Recebimento',6250,'income',1,'settled'),tx('Despesas',3862.55,'expense',2,'settled')],
   cards:const [CreditCardModel(id:'c',ownerMemberId:'u',walletId:'w',name:'Inter Mastercard',lastFourDigits:'1234',creditLimit:5000,closingDay:15,dueDay:25)],
   invoices:[CreditCardInvoiceModel(id:'i',cardId:'c',ownerMemberId:'u',referenceYear:2026,referenceMonth:5,closingDate:DateTime(2026,5,15),dueDate:DateTime(2026,5,25),total:892.40,createdAt:now,updatedAt:now)],
  ));
  addTearDown(controller.dispose);
  final key=GlobalKey();
  await tester.pumpWidget(RepaintBoundary(key:key,child:MaterialApp(home:WalletDetailsPage(wallet:wallet,controller:controller))));
  await tester.pumpAndSettle();
  expect(tester.takeException(),isNull);
  final boundary=key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final img=await boundary.toImage(pixelRatio:2);
  final data=await img.toByteData(format:ui.ImageByteFormat.png);
  await tester.runAsync(()=>File('/workspace/scratch/8d8b125faa5a/wallet-actual.png').writeAsBytes(data!.buffer.asUint8List()));
 });
}
