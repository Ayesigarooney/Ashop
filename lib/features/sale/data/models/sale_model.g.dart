// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SaleModelAdapter extends TypeAdapter<SaleModel> {
  @override
  final int typeId = 1;

  @override
  SaleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SaleModel(
      id: fields[0] as String,
      receiptNumber: fields[1] as String,
      items: (fields[2] as List).cast<SaleItemModel>(),
      subtotal: fields[3] as double,
      discountAmount: fields[4] as double,
      taxAmount: fields[5] as double,
      total: fields[6] as double,
      amountPaid: fields[7] as double,
      change: fields[8] as double,
      paymentMethod: fields[9] as String,
      createdAt: fields[10] as DateTime,
      customerName: fields[11] as String?,
      notes: fields[12] as String?,
      isRefunded: fields[13] as bool,
      refundedAt: fields[14] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SaleModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.receiptNumber)
      ..writeByte(2)
      ..write(obj.items)
      ..writeByte(3)
      ..write(obj.subtotal)
      ..writeByte(4)
      ..write(obj.discountAmount)
      ..writeByte(5)
      ..write(obj.taxAmount)
      ..writeByte(6)
      ..write(obj.total)
      ..writeByte(7)
      ..write(obj.amountPaid)
      ..writeByte(8)
      ..write(obj.change)
      ..writeByte(9)
      ..write(obj.paymentMethod)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.customerName)
      ..writeByte(12)
      ..write(obj.notes)
      ..writeByte(13)
      ..write(obj.isRefunded)
      ..writeByte(14)
      ..write(obj.refundedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaleModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SaleItemModelAdapter extends TypeAdapter<SaleItemModel> {
  @override
  final int typeId = 2;

  @override
  SaleItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SaleItemModel(
      productId: fields[0] as String,
      productName: fields[1] as String,
      unitPrice: fields[2] as double,
      quantity: fields[3] as int,
      totalPrice: fields[4] as double,
      discountPercent: fields[5] as double,
      note: fields[6] as String?,
      costPrice: fields[7] as double,
    );
  }

  @override
  void write(BinaryWriter writer, SaleItemModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.productName)
      ..writeByte(2)
      ..write(obj.unitPrice)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.totalPrice)
      ..writeByte(5)
      ..write(obj.discountPercent)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.costPrice);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaleItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
