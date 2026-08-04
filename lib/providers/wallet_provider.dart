import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/wallet_model.dart';
import '../services/firestore_service.dart';
import '../services/wallet_service.dart';

class WalletProvider extends ChangeNotifier {
  final WalletService _walletService;
  final FirestoreService _firestore;

  WalletModel? _wallet;
  List<TransactionModel> _transactions = [];
  StreamSubscription? _txSub;
  bool _loading = false;
  String? _error;

  WalletProvider(this._walletService, this._firestore);

  WalletModel? get wallet => _wallet;
  List<TransactionModel> get transactions => _transactions;
  bool get loading => _loading;
  String? get error => _error;
  String get balanceFormatted => '﷼ ${_wallet?.balance.toStringAsFixed(2) ?? '0.00'}';

  void subscribe(String userId, String userRole) {
    _walletService.getOrCreateWallet(userId, userRole).then((w) {
      _wallet = w;
      notifyListeners();
    });
    _txSub?.cancel();
    _txSub = _firestore.streamTransactions(userId).listen((txs) {
      _transactions = txs;
      notifyListeners();
    });
  }

  Future<void> topUp(double amount, {String? paymentMethod}) async {
    _loading = true;
    notifyListeners();
    try {
      final userId = _wallet?.userId;
      if (userId == null) return;
      await _walletService.topUp(userId, amount, paymentMethod: paymentMethod);
      final updated = await _firestore.getWallet(userId);
      _wallet = updated;
      _loading = false;
    } catch (e) {
      _error = e.toString();
      _loading = false;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _txSub?.cancel();
    super.dispose();
  }
}
