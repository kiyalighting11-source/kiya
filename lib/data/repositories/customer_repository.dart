import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer.dart';

class CustomerRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _table = 'customers';

  // جلب جميع العملاء
  Future<List<Customer>> getAllCustomers() async {
    try {
      final response = await _supabase
          .from(_table)
          .select('*')
          .order('name');

      return List<Customer>.from(
        response.map((json) => Customer.fromJson(json))
      );
    } catch (e) {
      throw Exception('خطأ في جلب العملاء: $e');
    }
  }

  // جلب عميل واحد بالـ ID
  Future<Customer?> getCustomerById(String id) async {
    try {
      final response = await _supabase
          .from(_table)
          .select('*')
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        return Customer.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('خطأ في جلب بيانات العميل: $e');
    }
  }

  // إضافة عميل جديد
  Future<Customer> createCustomer(Customer customer) async {
    try {
      final response = await _supabase
          .from(_table)
          .insert(customer.toJson())
          .select()
          .single();

      return Customer.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في إضافة العميل: $e');
    }
  }

  // تحديث بيانات عميل
  Future<Customer> updateCustomer(Customer customer) async {
    try {
      // التأكد من وجود ID
      if (customer.id == null) {
        throw Exception('معرف العميل مطلوب للتحديث');
      }

      final response = await _supabase
          .from(_table)
          .update(customer.toJson())
          .eq('id', customer.id!)
          .select()
          .single();

      return Customer.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في تحديث بيانات العميل: $e');
    }
  }

  // حذف عميل
  Future<void> deleteCustomer(String id) async {
    try {
      await _supabase
          .from(_table)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('خطأ في حذف العميل: $e');
    }
  }

  // البحث عن عميل
  Future<List<Customer>> searchCustomers(String query) async {
    try {
      final response = await _supabase
          .from(_table)
          .select('*')
          .ilike('name', '%$query%')
          .order('name');

      return List<Customer>.from(
        response.map((json) => Customer.fromJson(json))
      );
    } catch (e) {
      throw Exception('خطأ في البحث عن العملاء: $e');
    }
  }
}