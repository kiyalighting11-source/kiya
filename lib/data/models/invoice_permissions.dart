// lib/data/models/invoice_permissions.dart

import 'package:flutter/material.dart';

import 'invoice.dart';
import 'user.dart';

// ==================== INVOICE PERMISSIONS ====================
class InvoicePermissions {
  const InvoicePermissions._();

  // ==================== QUOTATION PERMISSIONS ====================

  /// هل يمكن إنشاء عرض سعر؟
  static bool canCreateQuotation(AppUser user) {
    return user.isActiveUser;
  }

  /// هل يمكن تحويل عرض السعر لفاتورة؟
  static bool canConvertToInvoice(InvoiceStatus status, AppUser user) {
    if (!user.isActiveUser) return false;
    if (user.isAdmin) {
      return status == InvoiceStatus.quotation &&
          status != InvoiceStatus.expired;
    }
    return status == InvoiceStatus.quotation && status != InvoiceStatus.expired;
  }

  /// هل يمكن إرسال عرض السعر للعميل؟
  static bool canSendQuotation(InvoiceStatus status, AppUser user) {
    if (!user.isActiveUser) return false;
    return status == InvoiceStatus.quotation || status == InvoiceStatus.draft;
  }

  /// هل يمكن تحديث صلاحية عرض السعر؟
  static bool canUpdateValidity(InvoiceStatus status, AppUser user) {
    return user.isAdmin &&
        user.isActiveUser &&
        status == InvoiceStatus.quotation;
  }

  /// هل يمكن طباعة عرض السعر؟
  static bool canPrintQuotation(InvoiceStatus status, AppUser user) {
    return user.isActiveUser &&
        (status == InvoiceStatus.quotation || status == InvoiceStatus.draft);
  }

  // ==================== GENERAL PERMISSIONS ====================

  /// هل يمكن إنشاء فاتورة جديدة؟
  static bool canCreateInvoice(AppUser user) {
    return user.isActiveUser;
  }

  /// هل يمكن تعديل الفاتورة؟
  static bool canEdit(InvoiceStatus status, AppUser user) {
    if (!user.isActiveUser) return false;
    if (!status.isEditable) return false;

    if (user.isAdmin) {
      return status.isEditable;
    }
    // الموظف يمكنه تعديل عرض السعر والمسودة والمكتملة
    return status.canBeEditedByEmployee;
  }

  /// هل يمكن تأكيد الفاتورة؟
  static bool canConfirm(InvoiceStatus status, AppUser user) {
    if (!user.isActiveUser) return false;
    // عرض السعر مسموح تأكيده
    return status.canBeConfirmed;
  }

  /// هل يمكن إلغاء الفاتورة؟
  static bool canCancel(InvoiceStatus status, AppUser user) {
    if (!user.isActiveUser) return false;
    if (!status.isCancellable) return false;

    if (user.isAdmin) {
      return status.isCancellable;
    }
    // الموظف يمكنه إلغاء عرض السعر والمسودة فقط
    return status == InvoiceStatus.draft || status == InvoiceStatus.quotation;
  }

  /// هل يمكن إكمال الدفع؟
  static bool canComplete(
    InvoiceStatus status,
    PaymentStatus payment,
    AppUser user,
  ) {
    if (!user.isActiveUser) return false;
    return status == InvoiceStatus.confirmed && payment != PaymentStatus.paid;
  }

  /// هل يمكن دفع الفاتورة (للمؤكدة وعرض السعر)؟
  static bool canPay(InvoiceStatus status, AppUser user) {
    if (!user.isActiveUser) return false;
    return status.canBePaid;
  }

  /// هل يمكن إرجاع الفاتورة؟
  static bool canReturn(InvoiceStatus status, AppUser user) {
    if (!user.isActiveUser) return false;
    return user.isAdmin && status.canBeReturned;
  }

  /// هل يمكن حذف الفاتورة؟
  static bool canDelete(InvoiceStatus status, AppUser user) {
    if (!user.isActiveUser) return false;
    return user.isAdmin && status.isDeletable;
  }

  /// هل يمكن طباعة الفاتورة؟
  static bool canPrint(InvoiceStatus status, AppUser user) {
    if (!user.isActiveUser) return false;
    return status.isPrintable;
  }

  /// هل يمكن إرسال الفاتورة للعميل؟
  static bool canSendToCustomer(InvoiceStatus status, AppUser user) {
    if (!user.isActiveUser) return false;
    return status.canSendToCustomer;
  }

  /// هل يمكن تغيير حالة الدفع؟
  static bool canChangePaymentStatus(InvoiceStatus status, AppUser user) {
    if (!user.isActiveUser) return false;
    if (user.isAdmin) {
      return status == InvoiceStatus.confirmed ||
          status == InvoiceStatus.completed;
    }
    return status == InvoiceStatus.confirmed;
  }

  /// هل يمكن إضافة/حذف منتجات من الفاتورة؟
  static bool canManageItems(InvoiceStatus status, AppUser user) {
    if (!user.isActiveUser) return false;
    if (user.isAdmin) {
      return status == InvoiceStatus.quotation ||
          status == InvoiceStatus.draft ||
          status == InvoiceStatus.pending ||
          status == InvoiceStatus.completed;
    }
    return status == InvoiceStatus.quotation ||
        status == InvoiceStatus.draft ||
        status == InvoiceStatus.completed;
  }

  // ==================== EMPLOYEE PERMISSIONS ====================

  /// صلاحيات الموظف الأساسية
  static Map<String, bool> getEmployeePermissions(InvoiceStatus status) {
    return {
      'canEdit': status.canBeEditedByEmployee,
      'canCancel':
          status == InvoiceStatus.draft || status == InvoiceStatus.quotation,
      'canConfirm': status.canBeConfirmed,
      'canComplete': status == InvoiceStatus.confirmed,
      'canPay': status.canBePaid,
      'canPrint': status.isPrintable,
      'canSendToCustomer': status.canSendToCustomer,
      'canCreateQuotation': true,
      'canCreateInvoice': true,
      'canManageItems': status.canBeEditedByEmployee,
      'canChangePaymentStatus': status == InvoiceStatus.confirmed,
      'canReturn': false,
      'canDelete': false,
    };
  }

  /// صلاحيات المدير الكاملة
  static Map<String, bool> getAdminPermissions(InvoiceStatus status) {
    return {
      'canEdit': status.isEditable,
      'canCancel': status.isCancellable,
      'canConfirm': status.canBeConfirmed,
      'canComplete': status == InvoiceStatus.confirmed,
      'canPay': status.canBePaid,
      'canPrint': status.isPrintable,
      'canSendToCustomer': status.canSendToCustomer,
      'canCreateQuotation': true,
      'canCreateInvoice': true,
      'canManageItems': status.isEditable,
      'canChangePaymentStatus':
          status == InvoiceStatus.confirmed ||
          status == InvoiceStatus.completed,
      'canDelete': status.isDeletable,
      'canReturn': status.canBeReturned,
      'canUpdateValidity': status == InvoiceStatus.quotation,
      'canConvertToInvoice': status == InvoiceStatus.quotation,
    };
  }

  /// الحصول على الصلاحيات حسب دور المستخدم
  static Map<String, bool> getPermissions(InvoiceStatus status, AppUser user) {
    if (user.isAdmin) {
      return getAdminPermissions(status);
    }
    return getEmployeePermissions(status);
  }

  // ==================== BULK PERMISSIONS ====================

  /// هل يمكن تنفيذ عملية على مجموعة من الفواتير؟
  static bool canBulkAction(
    List<InvoiceStatus> statuses,
    String action,
    AppUser user,
  ) {
    if (!user.isActiveUser) return false;

    switch (action) {
      case 'delete':
        if (!user.isAdmin) return false;
        return statuses.every((s) => s.isDeletable);

      case 'print':
        return statuses.every((s) => s.isPrintable);

      case 'confirm':
        return statuses.every((s) => s.canBeConfirmed);

      case 'cancel':
        if (!user.isAdmin) {
          return statuses.every(
            (s) => s == InvoiceStatus.draft || s == InvoiceStatus.quotation,
          );
        }
        return statuses.every((s) => s.isCancellable);

      case 'pay':
        return statuses.every((s) => s.canBePaid);

      default:
        return false;
    }
  }

  // ==================== STATUS TRANSITION PERMISSIONS ====================

  /// هل يمكن الانتقال من حالة إلى أخرى؟
  static bool canTransition(
    InvoiceStatus from,
    InvoiceStatus to,
    AppUser user,
  ) {
    if (!user.isActiveUser) return false;

    // نفس الحالة
    if (from == to) return true;

    // التحقق من الانتقالات المسموحة
    switch (from) {
      case InvoiceStatus.quotation:
        return to == InvoiceStatus.draft ||
            to == InvoiceStatus.expired ||
            to == InvoiceStatus.cancelled ||
            to == InvoiceStatus.confirmed;

      case InvoiceStatus.draft:
        return to == InvoiceStatus.confirmed ||
            to == InvoiceStatus.pending ||
            to == InvoiceStatus.cancelled;

      case InvoiceStatus.confirmed:
        return to == InvoiceStatus.completed || to == InvoiceStatus.cancelled;

      case InvoiceStatus.completed:
        return to == InvoiceStatus.returned;

      case InvoiceStatus.pending:
        if (user.isAdmin) {
          return to == InvoiceStatus.confirmed ||
              to == InvoiceStatus.draft ||
              to == InvoiceStatus.cancelled;
        }
        return to == InvoiceStatus.confirmed;

      case InvoiceStatus.cancelled:
      case InvoiceStatus.returned:
      case InvoiceStatus.expired:
        return false;
    }
  }

  /// الحصول على الحالات التالية المسموحة
  static List<InvoiceStatus> getAllowedNextStatuses(
    InvoiceStatus current,
    AppUser user,
  ) {
    if (!user.isActiveUser) return [];

    List<InvoiceStatus> allowed = [];

    for (var status in InvoiceStatus.values) {
      if (canTransition(current, status, user)) {
        allowed.add(status);
      }
    }

    return allowed;
  }

  // ==================== VIEW PERMISSIONS ====================

  /// هل يمكن عرض الفاتورة؟
  static bool canView(InvoiceStatus status, AppUser user) {
    return user.isActiveUser;
  }

  /// هل يمكن عرض جميع الفواتير؟
  static bool canViewAll(AppUser user) {
    return user.isAdmin;
  }

  /// هل يمكن عرض فواتير الموظفين الآخرين؟
  static bool canViewOtherEmployeesInvoices(AppUser user) {
    return user.isAdmin;
  }

  // ==================== REPORT PERMISSIONS ====================

  /// هل يمكن إنشاء تقارير؟
  static bool canCreateReports(AppUser user) {
    return user.isAdmin || user.isActiveUser;
  }

  /// هل يمكن إنشاء تقارير مالية؟
  static bool canCreateFinancialReports(AppUser user) {
    return user.isAdmin;
  }

  // ==================== EXPORT PERMISSIONS ====================

  /// هل يمكن تصدير الفواتير؟
  static bool canExportInvoices(AppUser user) {
    return user.isAdmin;
  }

  /// هل يمكن تصدير الفواتير كـ PDF؟
  static bool canExportPDF(AppUser user) {
    return user.isActiveUser;
  }

  // ==================== EMAIL PERMISSIONS ====================

  /// هل يمكن إرسال الفاتورة عبر البريد الإلكتروني؟
  static bool canEmailInvoice(InvoiceStatus status, AppUser user) {
    if (!user.isActiveUser) return false;
    return status.canSendToCustomer && user.isAdmin;
  }

  // ==================== HELPERS ====================

  /// الحصول على رسالة الخطأ المناسبة عند عدم وجود صلاحية
  static String getPermissionDeniedMessage(String action, AppUser user) {
    if (!user.isActiveUser) {
      return '❌ الحساب غير نشط. يرجى التواصل مع الإدارة.';
    }

    switch (action) {
      case 'edit':
        return '❌ ليس لديك صلاحية لتعديل هذه الفاتورة.';
      case 'delete':
        return '❌ ليس لديك صلاحية لحذف هذه الفاتورة.';
      case 'confirm':
        return '❌ ليس لديك صلاحية لتأكيد هذه الفاتورة.';
      case 'cancel':
        return '❌ ليس لديك صلاحية لإلغاء هذه الفاتورة.';
      case 'complete':
        return '❌ ليس لديك صلاحية لإكمال هذه الفاتورة.';
      case 'return':
        return '❌ ليس لديك صلاحية لإرجاع هذه الفاتورة.';
      case 'print':
        return '❌ ليس لديك صلاحية لطباعة هذه الفاتورة.';
      case 'send':
        return '❌ ليس لديك صلاحية لإرسال هذه الفاتورة.';
      case 'pay':
        return '❌ ليس لديك صلاحية للدفع على هذه الفاتورة.';
      default:
        return '❌ ليس لديك صلاحية لتنفيذ هذا الإجراء.';
    }
  }

  /// التحقق من الصلاحية وعرض رسالة خطأ إذا لزم الأمر
  static bool checkPermissionAndShowError(
    BuildContext context,
    bool hasPermission,
    String action,
    AppUser user,
  ) {
    if (hasPermission) return true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(getPermissionDeniedMessage(action, user)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    return false;
  }
}

// ==================== EXTENSION METHODS ====================

extension InvoiceStatusExtension on InvoiceStatus {
  /// الحصول على الصلاحيات للمستخدم الحالي
  Map<String, bool> getPermissionsForUser(AppUser user) {
    return InvoicePermissions.getPermissions(this, user);
  }

  /// هل المستخدم لديه صلاحية معينة؟
  bool userHasPermission(AppUser user, String permission) {
    final permissions = InvoicePermissions.getPermissions(this, user);
    return permissions[permission] ?? false;
  }

  /// الحصول على الحالات التالية المسموحة للمستخدم
  List<InvoiceStatus> getAllowedNextStatuses(AppUser user) {
    return InvoicePermissions.getAllowedNextStatuses(this, user);
  }
}

extension UserPermissionsExtension on AppUser {
  /// الحصول على كل صلاحيات المستخدم لفاتورة بحالة معينة
  Map<String, bool> getInvoicePermissions(InvoiceStatus status) {
    return InvoicePermissions.getPermissions(status, this);
  }

  /// هل المستخدم لديه صلاحية معينة لفاتورة بحالة معينة؟
  bool hasInvoicePermission(InvoiceStatus status, String permission) {
    final permissions = InvoicePermissions.getPermissions(status, this);
    return permissions[permission] ?? false;
  }

  /// هل المستخدم يمكنه تنفيذ إجراء معين على فاتورة بحالة معينة؟
  bool canPerformAction(InvoiceStatus status, String action) {
    switch (action) {
      case 'create_quotation':
        return InvoicePermissions.canCreateQuotation(this);
      case 'create_invoice':
        return InvoicePermissions.canCreateInvoice(this);
      case 'edit':
        return InvoicePermissions.canEdit(status, this);
      case 'confirm':
        return InvoicePermissions.canConfirm(status, this);
      case 'cancel':
        return InvoicePermissions.canCancel(status, this);
      case 'complete':
        return InvoicePermissions.canComplete(
          status,
          PaymentStatus.unpaid,
          this,
        );
      case 'pay':
        return InvoicePermissions.canPay(status, this);
      case 'delete':
        return InvoicePermissions.canDelete(status, this);
      case 'print':
        return InvoicePermissions.canPrint(status, this);
      case 'send':
        return InvoicePermissions.canSendToCustomer(status, this);
      case 'return':
        return InvoicePermissions.canReturn(status, this);
      case 'convert_to_invoice':
        return InvoicePermissions.canConvertToInvoice(status, this);
      default:
        return false;
    }
  }
}
