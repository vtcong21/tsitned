﻿USE master;
GO
ALTER DATABASE PKNHAKHOA SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

-- DROP DATABASE PKNHAKHOA;

CREATE DATABASE PKNHAKHOA;
GO

USE PKNHAKHOA;
GO

CREATE TABLE KHACHHANG 
(
    SODT VARCHAR(10) PRIMARY KEY,
    HOTEN NVARCHAR(50),
    PHAI NVARCHAR(5) CHECK(PHAI IN (N'Nam', N'Nữ')),
    NGAYSINH DATE,
	DIACHI NVARCHAR(250),
	MATKHAU VARCHAR(20),
	_DAKHOA BIT DEFAULT 0
);


CREATE TABLE NHASI 
(
    MANS VARCHAR(10) PRIMARY KEY,
    HOTEN NVARCHAR(50),
    PHAI NVARCHAR(5) CHECK(PHAI IN (N'Nam', N'Nữ')),
    GIOITHIEU NVARCHAR(500),
	MATKHAU VARCHAR(20),
	_DAKHOA BIT DEFAULT 0
);

CREATE TABLE NHANVIEN 
(
    MANV VARCHAR(10) PRIMARY KEY,
    HOTEN NVARCHAR(50),
    PHAI NVARCHAR(5) CHECK(PHAI IN (N'Nam', N'Nữ')),
    VITRICV NVARCHAR(50),
	MATKHAU VARCHAR(20),
	_DAKHOA BIT DEFAULT 0
);

CREATE TABLE QTV 
(
    MAQTV VARCHAR(10) PRIMARY KEY,
    HOTEN NVARCHAR(50),
    PHAI NVARCHAR(5) CHECK(PHAI IN (N'Nam', N'Nữ')),
	MATKHAU VARCHAR(20),
);
CREATE TABLE CA
(
	MACA VARCHAR(10) PRIMARY KEY,
	GIOBATDAU TIME,
	GIOKETTHUC TIME
);

CREATE TABLE LOAITHUOC
(
	MATHUOC VARCHAR(10) PRIMARY KEY,
    TENTHUOC NVARCHAR(50),
    DONVITINH NVARCHAR(20),
	CHIDINH NVARCHAR(200),
	SLTON INT CHECK (SLTON >= 0),
	SLNHAP INT CHECK (SLNHAP > 0),
	SLDAHUY INT CHECK (SLDAHUY >= 0),
	NGAYHETHAN DATE,
	DONGIA FLOAT CHECK (DONGIA > 0)
);

CREATE TABLE CHITIETTHUOC
(
	MATHUOC VARCHAR(10),
	SOTT INT,
	SODT VARCHAR(10),
	SOLUONG INT CHECK (SOLUONG > 0),
	THOIDIEMDUNG NVARCHAR(200)
    PRIMARY KEY(SODT, SOTT, MATHUOC)
);
CREATE TABLE LOAIDICHVU
(
	MADV VARCHAR(10) PRIMARY KEY,
    TENDV NVARCHAR(50),
    MOTA NVARCHAR(500),
	DONGIA FLOAT CHECK (DONGIA > 0)
);


CREATE TABLE CHITIETDV
(
	MADV VARCHAR(10),
	SOTT INT,
	SODT VARCHAR(10),
	SOLUONG INT CHECK(SOLUONG > 0)
    PRIMARY KEY(SODT, SOTT, MADV)
);


CREATE TABLE LICHRANH
(
	MANS VARCHAR(10),
	SOTT INT,
	MACA VARCHAR(10),
	NGAY DATE,
    PRIMARY KEY(MANS, SOTT)
);

CREATE TABLE LICHHEN
(
	MANS VARCHAR(10),
	SOTT INT,
	LYDOKHAM NVARCHAR(200),
	SODT VARCHAR(10)
	PRIMARY KEY(MANS, SOTT, SODT)
);

CREATE TABLE HOSOBENH
(
	SODT VARCHAR(10),
	SOTT INT,
	NGAYKHAM DATE,
	DANDO NVARCHAR(500),
	MANS VARCHAR(10),
	_DAXUATHOADON BIT DEFAULT 0
	PRIMARY KEY(SODT, SOTT)
);

CREATE TABLE HOADON
(
	SODT VARCHAR(10),
	SOTT INT,
	NGAYXUAT DATE,
	TONGCHIPHI FLOAT CHECK (TONGCHIPHI > 0),
	_DATHANHTOAN BIT DEFAULT 0,
	MANV VARCHAR(10)
	PRIMARY KEY(SODT, SOTT)
);

--PK1 LICHRANH(MANS) --> NHASI(MANS)
ALTER TABLE LICHRANH
ADD CONSTRAINT FK_LR_NS
FOREIGN KEY(MANS)
REFERENCES NHASI(MANS);

--PK2 LICHRANH(MACA) --> CA(MACA)
ALTER TABLE LICHRANH
ADD CONSTRAINT FK_LR_CA
FOREIGN KEY(MACA)
REFERENCES CA(MACA);

--PK3 LICHHEN(MANS, SOTT) --> LICHRANH(MANS, SOTT)
ALTER TABLE LICHHEN
ADD CONSTRAINT FK_LH_LR
FOREIGN KEY(MANS, SOTT)
REFERENCES LICHRANH(MANS, SOTT);

--PK4 LICHHEN(SODT) --> KHACHHANG(SODT)
ALTER TABLE LICHHEN
ADD CONSTRAINT FK_LH_KH
FOREIGN KEY(SODT)
REFERENCES KHACHHANG(SODT);

--PK4 HOSOBENH(MANS) --> NHASI(MANS)
ALTER TABLE HOSOBENH
ADD CONSTRAINT FK_HSB_NS
FOREIGN KEY(MANS)
REFERENCES NHASI(MANS);

--PK5 HOSOBENH(SODT) --> KHACHHANG(SODT)
ALTER TABLE HOSOBENH
ADD CONSTRAINT FK_HSB_KH
FOREIGN KEY(SODT)
REFERENCES KHACHHANG(SODT);

--PK6 HOADON(SODT, SOTT) --> HOSOBENH(SODT, SOTT)
ALTER TABLE HOADON
ADD CONSTRAINT FK_HD_HSB
FOREIGN KEY(SODT, SOTT)
REFERENCES HOSOBENH(SODT, SOTT);

--PK7 HOADON(MANV) --> NHANVIEN(MANV)
ALTER TABLE HOADON
ADD CONSTRAINT FK_HD_NV
FOREIGN KEY(MANV)
REFERENCES NHANVIEN(MANV);

--PK8 CHITIETDV(MADV) --> LOAIDICHVU(MADV)
ALTER TABLE CHITIETDV
ADD CONSTRAINT FK_CTDV_LDV
FOREIGN KEY(MADV)
REFERENCES LOAIDICHVU(MADV);

--PK9 CHITIETDV(SODT, SOTT) --> HOSOBENH(SODT, SOTT)
ALTER TABLE CHITIETDV
ADD CONSTRAINT FK_CTDV_HSB
FOREIGN KEY(SODT, SOTT)
REFERENCES HOSOBENH(SODT, SOTT);

--PK10 CHITIETTHUOC(MATHUOC) --> LOAITHUOC(MATHUOC)
ALTER TABLE CHITIETTHUOC
ADD CONSTRAINT FK_CTT_LT
FOREIGN KEY(MATHUOC)
REFERENCES LOAITHUOC(MATHUOC);

--PK11 CHITIETTHUOC(SODT, SOTT) --> HOSOBENH(SODT, SOTT)
ALTER TABLE CHITIETTHUOC
ADD CONSTRAINT FK_CTT_HSB
FOREIGN KEY(SODT, SOTT)
REFERENCES HOSOBENH(SODT, SOTT);
