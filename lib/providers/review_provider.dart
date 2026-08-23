import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review_model.dart';

class ReviewProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  
  List<ReviewModel> _reviews = [];
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<ReviewModel> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Get reviews for a specific product
  List<ReviewModel> getReviewsForProduct(String productId) {
    return _reviews.where((r) => r.productId == productId).toList();
  }
  
  // Get reviews by a specific buyer
  List<ReviewModel> getReviewsByBuyer(String buyerId) {
    return _reviews.where((r) => r.buyerId == buyerId).toList();
  }
  
  // Get reviews for products by a specific seller
  List<ReviewModel> getReviewsForSeller(String sellerId) {
    return _reviews.where((r) => r.sellerId == sellerId).toList();
  }
  
  // Check if user has already reviewed a product
  bool hasUserReviewed(String productId, String buyerId) {
    return _reviews.any((r) => r.productId == productId && r.buyerId == buyerId);
  }
  
  // Get user's review for a product
  ReviewModel? getUserReview(String productId, String buyerId) {
    try {
      return _reviews.firstWhere((r) => r.productId == productId && r.buyerId == buyerId);
    } catch (e) {
      return null;
    }
  }
  
  // Calculate average rating for a product
  double getAverageRating(String productId) {
    final productReviews = getReviewsForProduct(productId);
    if (productReviews.isEmpty) return 0.0;
    
    final sum = productReviews.fold<int>(0, (prev, review) => prev + review.rating);
    return sum / productReviews.length;
  }
  
  // Fetch reviews for a product
  Future<void> fetchReviewsForProduct(String productId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _supabase
          .from('reviews')
          .select('*, buyer:profiles!reviews_buyer_id_fkey(name, email), seller:profiles!reviews_seller_id_fkey(name)')
          .eq('product_id', productId)
          .order('created_at', ascending: false);
      
      final List<ReviewModel> fetchedReviews = (response as List)
          .map((json) => ReviewModel.fromJson(json))
          .toList();
      
      // Remove old reviews for this product and add new ones
      _reviews.removeWhere((r) => r.productId == productId);
      _reviews.addAll(fetchedReviews);
      
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('Error fetching reviews: $e');
      }
    }
  }
  
  // Fetch all reviews for seller (to show on seller dashboard)
  Future<void> fetchReviewsForSeller(String sellerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _supabase
          .from('reviews')
          .select('*, buyer:profiles!reviews_buyer_id_fkey(name, email), seller:profiles!reviews_seller_id_fkey(name), product:products(title, image_urls)')
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);
      
      _reviews = (response as List)
          .map((json) => ReviewModel.fromJson(json))
          .toList();
      
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('Error fetching seller reviews: $e');
      }
    }
  }
  
  // Submit a new review
  Future<bool> submitReview({
    required String productId,
    required String buyerId,
    required String sellerId,
    required int rating,
    String? reviewText,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Check if user already reviewed this product
      if (hasUserReviewed(productId, buyerId)) {
        _error = 'You have already reviewed this product. You can update your existing review.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      final newReview = {
        'product_id': productId,
        'buyer_id': buyerId,
        'seller_id': sellerId,
        'rating': rating,
        'review_text': reviewText,
      };
      
      final response = await _supabase
          .from('reviews')
          .insert(newReview)
          .select('*, buyer:profiles!reviews_buyer_id_fkey(name, email), seller:profiles!reviews_seller_id_fkey(name)')
          .single();
      
      final createdReview = ReviewModel.fromJson(response);
      _reviews.insert(0, createdReview);
      
      _isLoading = false;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('Error submitting review: $e');
      }
      return false;
    }
  }
  
  // Update an existing review
  Future<bool> updateReview({
    required String reviewId,
    required int rating,
    String? reviewText,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final updatedData = {
        'rating': rating,
        'review_text': reviewText,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      await _supabase
          .from('reviews')
          .update(updatedData)
          .eq('id', reviewId);
      
      // Update local review
      final index = _reviews.indexWhere((r) => r.id == reviewId);
      if (index != -1) {
        _reviews[index] = _reviews[index].copyWith(
          rating: rating,
          reviewText: reviewText,
          updatedAt: DateTime.now(),
        );
      }
      
      _isLoading = false;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('Error updating review: $e');
      }
      return false;
    }
  }
  
  // Delete a review
  Future<bool> deleteReview(String reviewId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _supabase
          .from('reviews')
          .delete()
          .eq('id', reviewId);
      
      _reviews.removeWhere((r) => r.id == reviewId);
      
      _isLoading = false;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        print('Error deleting review: $e');
      }
      return false;
    }
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // Clear all reviews (useful when logging out)
  void clearReviews() {
    _reviews = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
