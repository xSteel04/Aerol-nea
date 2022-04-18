use master;
go
Declare @DBstr as nvarchar(max) = 'DbAerolinea';
Declare  @strUse as nvarchar(max), @strCrear as nvarchar(max),@strDrop as nvarchar(max);
DECLARE @kill varchar(8000) = ''; 

if exists(select count([name]) from sys.databases where [name] = @DBstr)
begin

select 'Si existe entonces (Desconectamos Usurios)';			 
SELECT @kill = @kill + 'kill ' + CONVERT(varchar(5), session_id) + ';'  
FROM sys.dm_exec_sessions  WHERE database_id  = db_id(@DBstr) and status ='running'
			
Exec(@kill); -- desconectando cualquier login activo 

end

if (select count([name]) from sys.databases where [name] = @DBstr)>0
begin
				
select 'Si existe entonces (Eliminar + Crear + Usar)';
set  @strDrop = 'Drop database '+@DBstr;
set  @strCrear = 'create database '+@DBstr  
set  @strUse = 'use '+@DBstr 
exec(@strDrop);
exec(@strCrear);
exec(@strUse);

end

else 
begin 

select 'No existe entonces (Crear + Usar)';
set  @strCrear = 'create database '+@DBstr  
set  @strUse = 'use '+@DBstr 
exec(@strCrear); 
exec(@strUse);
				
end 

if (select count([name]) from sys.databases where [name] = @DBstr)>0
begin
			
use DbAerolinea;
set  @strUse = 'use '+@DBstr 
exec(@strUse);
exec(@strUse+'

Create table pais (
idpais int not null primary key,
nombre_pais varchar(30) not null unique,
)

Create table pasajero (
idpasajero int not null primary key,
nombre_pasajero varchar(30) not null,
apellido_1 varchar(20) not null,
apellido_2 varchar(20) not null,
tipo_documento varchar(20) not null,
numero_documento varchar(15) not null,
fecha_nacimiento date not null,
idpais int not null,
telefono varchar(15) null,
correo varchar(20) not null,
clave varchar(20) not null,
)

Create table aeropuerto (
idaeropuerto int not null primary key,
nombre_aeropuerto varchar(40) not null unique,
idpais int not null,
)

Create table aerolinea (
idaerolinea int not null primary key,
ruc char(11) not null unique,
nombre_aerolinea varchar(30) not null unique,
)

Create table avion (
idavion int not null primary key,
idaerolinea int not null,
fabricante_avion varchar(30) null,
tipo_avion varchar(30) null,
capacidad int not null,
)

Create table asiento (
idasiento int not null primary key,
letra_asiento char(1) not null,
fila int not null,
)

Create table tarifa(
idtarifa int not null primary key,
clase varchar(20) not null unique,
precio money not null,
impuesto money not null,
)

Create table reserva(
idreserva int not null primary key,
costo money not null,
fecha date null,
observacion varchar(300) null,
)

Alter table reserva
Add constraint dfl_reserva_fecha
Default getdate() for fecha

Create table vuelo(
idasiento int not null,
idaeropuerto int not null,
idreserva int not null,
idavion int not null,
idtarifa int not null,
)
Alter table vuelo
Add primary key nonclustered (idasiento,idaeropuerto,idreserva,idavion)

CREATE TABLE pago(
idpago int not null primary key identity,
idreserva int not null,
idpasajero int not null,
fecha date default getdate(),
monto money not null,
tipo_comprobante varchar(20) not null,
numero_comprobante varchar(15)not null,
impuesto decimal (5,2) not null,
)
Alter table pago
Add constraint chk_pago_fecha
Check (fecha<=getdate())
-----------------------------------------------------------------------------------------
Alter table pasajero
Add constraint FK_pasajero_pais
Foreign key (idpais) references pais (idpais)

Alter table aeropuerto
Add constraint FK_aeropuerto_pais
Foreign key(idpais) references pais (idpais)

Alter table pago
Add constraint FK_pago_pasajero
Foreign key (idpasajero) references pasajero (idpasajero)

Alter table pago
Add constraint fk_pago_reserva
Foreign key (idreserva) references reserva(idreserva)

Alter table avion
Add constraint FK_avion_aerolinea
Foreign key (idaerolinea) references aerolinea(idaerolinea)

Alter table vuelo
Add constraint FK_vuelo_asiento
Foreign key (idasiento) references asiento(idasiento)

Alter table vuelo
Add constraint FK_vuelo_reserva
Foreign key (idreserva) references reserva(idreserva)

Alter table vuelo
Add constraint FK_vuelo_avion
Foreign key (idavion) references avion(idavion)

Alter table vuelo
Add constraint FK_vuelo_tarifa
Foreign key (idtarifa) references tarifa(idtarifa)

Alter table vuelo
Add constraint FK_vuelo_aeropuerto
Foreign key (idaeropuerto) references aeropuerto(idaeropuerto)

');

end
-----------------------------------------------------------------------------------------
--SP listado de paises y su total de pasajeros

if object_id('pasajeroxpais') is not null
begin 
	drop procedure pasajeroxpais
end
go

create procedure pasajeroxpais
as
begin transaction
select pai.nombre_pais, count(*) as Total
from pasajero pas inner join pais pai
on pas.idpais = pai.idpais
group by pai.nombre_pais
commit transaction
go

exec pasajeroxpais


/*Muestra los pagos de un determinado pasajero con parámetro de busqueda
el nmero de documento del pasajero*/

if object_id('pagoxpasajero') is not null
begin 
	drop procedure pagoxpasajero
end
go

create procedure pagoxpasajero
@numero_documento varchar(15)
as
select fecha, monto, tipo_comprobante, numero_comprobante
from pago where idpasajero = (
select idpasajero from pasajero where numero_documento = @numero_documento)
go

--exec pagoxpasajero '114796'

--Registra un nuevo paú usando como parámetro los campos de la tabla paú

if object_id('nuevopais') is not null
begin 
	drop procedure nuevopais
end
go

create procedure nuevopais
@idpais int,
@nombre_pais varchar(30)
as

insert into pais (idpais, nombre_pais)
values (@idpais, @nombre_pais)
go

--nuevopais '3', 'El Salvador'

select * from pais

--Retorna el total de pagos recibidos de una determinada fecha

if object_id('pagoxfecha') is not null
begin 
	drop procedure pagoxfecha
end
go

create procedure pagoxfecha
@fecha date,
@total money output
as

select @total = sum(monto) from pago
where fecha = @fecha
go

--Ejecución
declare @t money
exec pagoxfecha '2020-09-06', @total = @t output
print 'Total: ' + cast(@t as char(10)) 
go

-------------------------------------------------------------------------------------
/*Trigger que muestra un mensaje cuando se inserta o actualiza un registro de la
tabla pasajero*/

create trigger trmensaje_pasajero
on pasajero 
for insert, update
as
	print 'Pasajero actualizado correctamente '
go

--insert into pasajero values (4, 'Luisa', 'Hernandez', 'Fonseca', 'Pasaporte', '00158', '1999-09-06', 2, '77558694', 'Luisa@gmail.com', 'Luisa123')

update pasajero set nombre_pasajero = 'Mario'
where numero_documento = '114796'

If object_id('validapago') is not null
begin
	drop trigger validapago
end
go

create trigger validapago
on pago
for insert
as
if (select monto from inserted)<=0
begin
rollback transaction
print 'No puede registrar monto menor o igual a cero'
end
else
print 'Pago registrado correctamente'
go

/*insert into pago (idreserva,fecha,idpasajero,monto,tipo_comprobante,
numero_comprobante,impuesto) values(4,'2020-09-06',4,0,'Voucher',
'0001-00015',0.18)*/

---------------------------------------------------------------------------------------------

CREATE PROCEDURE SP_UIPAIS
(
@idpais as int, 
@nombre_pais as varchar(30)
)
AS
BEGIN
SET XACT_ABORT ON
DECLARE @trans NVARCHAR(100)
SELECT @trans = 'trans_IPais'
BEGIN TRY
BEGIN TRANSACTION @trans
				
MERGE pais AS TARGET
USING(SELECT @Idpais, @nombre_pais) AS SOURCE(IDPAIS, NOMBREPAIS)

ON (TARGET.IDPAIS = SOURCE.IDPAIS)

WHEN MATCHED THEN 
UPDATE SET nombre_pais = SOURCE.NOMBREPAIS
--DELETE
WHEN NOT MATCHED THEN
INSERT VALUES(SOURCE.IDPAIS, SOURCE.NOMBREPAIS);
COMMIT TRANSACTION @trans
END TRY

BEGIN CATCH
			
DECLARE @STRERROR NVARCHAR(2048)
SELECT @STRERROR = ERROR_MESSAGE()
PRINT 'Ha ocurrido el siguiente error: ' + @STRERROR	
IF @@trancount > 0 and xact_state() in (1, -1)
ROLLBACK TRANSACTION @TRANS
RAISERROR ( @STRERROR, 16, 1)
END CATCH	
END 
GO

--EXEC SP_UIPAISES '3' , 'Peru'
-----------------------------------------------------------------------------

CREATE PROCEDURE SP_UIPASAJERO
(
@idpasajero int ,
@nombre_pasajero varchar(30), 
@apellido_1 varchar(20) ,
@apellido_2 varchar(20) ,
@tipo_documento varchar(20), 
@numero_documento varchar(15), 
@fecha_nacimiento date ,
@idpais int ,
@telefono varchar(15),
@correo varchar(20) ,
@clave varchar(20) 
)
AS
BEGIN
SET XACT_ABORT ON
DECLARE @trans NVARCHAR(100)
SELECT @trans = 'trans_IAeropuerto'
BEGIN TRY
BEGIN TRANSACTION @trans
				
MERGE pasajero AS TARGET
USING(SELECT @idpasajero, @nombre_pasajero, @apellido_1, @apellido_2, @tipo_documento, @numero_documento, @fecha_nacimiento, @idpais, @telefono, @correo, @clave)
AS SOURCE(IDPASAJERO, NOMBREPASAJERO, APELLLIDO1, APELLIDO2, TIPODOC, NUMDOC, FECHANAC, IDPAIS, TELF, CORREO, CLAVE)


ON (TARGET.IDPASAJERO = SOURCE.IDPASAJERO)

WHEN MATCHED THEN 
UPDATE SET @nombre_pasajero = SOURCE.NOMBREPASAJERO, @apellido_1 = SOURCE.APELLLIDO1, @apellido_2 = SOURCE.APELLIDO2, @tipo_documento = SOURCE.TIPODOC, @numero_documento = SOURCE.NUMDOC, @fecha_nacimiento = SOURCE.FECHANAC, @telefono = SOURCE.TELF, @correo = SOURCE.CORREO, @clave = SOURCE.CLAVE
--DELETE
WHEN NOT MATCHED THEN
INSERT VALUES(SOURCE.IDPASAJERO, SOURCE.NOMBREPASAJERO, SOURCE.APELLLIDO1, SOURCE.APELLIDO2, SOURCE.TIPODOC, SOURCE.NUMDOC, SOURCE.FECHANAC, SOURCE.IDPAIS, SOURCE.TELF, SOURCE.CORREO, SOURCE.CLAVE);
COMMIT TRANSACTION @trans
END TRY

BEGIN CATCH
			
DECLARE @STRERROR NVARCHAR(2048)
SELECT @STRERROR = ERROR_MESSAGE()
PRINT 'Ha ocurrido el siguiente error: ' + @STRERROR	
IF @@trancount > 0 and xact_state() in (1, -1)
ROLLBACK TRANSACTION @TRANS
RAISERROR ( @STRERROR, 16, 1)
END CATCH	
END 
GO
---------------------------------------------------------------------------------------

CREATE PROCEDURE SP_UIAEROPUERTO
(
@idaeropuerto int,
@nombre_aeropuerto varchar(40)
)
AS
BEGIN
SET XACT_ABORT ON
DECLARE @trans NVARCHAR(100)
SELECT @trans = 'trans_IAeropuerto'
BEGIN TRY
BEGIN TRANSACTION @trans
				
MERGE aeropuerto AS TARGET
USING(SELECT @idaeropuerto, @nombre_aeropuerto) AS SOURCE(IDAEROPUERTO, NOMBREAEROPUERTO)

ON (TARGET.IDAEROPUERTO = SOURCE.IDAEROPUERTO)

WHEN MATCHED THEN 
UPDATE SET @nombre_aeropuerto = SOURCE.NOMBREAEROPUERTO
--DELETE
WHEN NOT MATCHED THEN
INSERT VALUES(SOURCE.IDAEROPUERTO, SOURCE.NOMBREAEROPUERTO);
COMMIT TRANSACTION @trans
END TRY

BEGIN CATCH
			
DECLARE @STRERROR NVARCHAR(2048)
SELECT @STRERROR = ERROR_MESSAGE()
PRINT 'Ha ocurrido el siguiente error: ' + @STRERROR	
IF @@trancount > 0 and xact_state() in (1, -1)
ROLLBACK TRANSACTION @TRANS
RAISERROR ( @STRERROR, 16, 1)
END CATCH	
END 
GO

-----------------------------------------------------------------------------------------------------

CREATE PROCEDURE SP_UIAEROLINEA
(
@idaerolinea int ,
@ruc char(11) ,
@nombre_aerolinea varchar(30) 
)
AS
BEGIN
SET XACT_ABORT ON
DECLARE @trans NVARCHAR(100)
SELECT @trans = 'trans_IAerolinea'
BEGIN TRY
BEGIN TRANSACTION @trans
				
MERGE aerolinea AS TARGET
USING(SELECT @idaerolinea, @ruc, @nombre_aerolinea) AS SOURCE(IDAEROLINEA, RUC, NOMBREAEROLINEA)

ON (TARGET.IDAEROLINEA = SOURCE.IDAEROLINEA)

WHEN MATCHED THEN 
UPDATE SET @nombre_aerolinea = SOURCE.NOMBREAEROLINEA, @ruc = SOURCE.RUC
--DELETE
WHEN NOT MATCHED THEN
INSERT VALUES(SOURCE.IDAEROLINEA, SOURCE.RUC, SOURCE.NOMBREAEROLINEA);
COMMIT TRANSACTION @trans
END TRY

BEGIN CATCH
			
DECLARE @STRERROR NVARCHAR(2048)
SELECT @STRERROR = ERROR_MESSAGE()
PRINT 'Ha ocurrido el siguiente error: ' + @STRERROR	
IF @@trancount > 0 and xact_state() in (1, -1)
ROLLBACK TRANSACTION @TRANS
RAISERROR ( @STRERROR, 16, 1)
END CATCH	
END 
GO

---------------------------------------------------------------------------------------
CREATE PROCEDURE SP_UIAVION
(
@idavion int ,
@idaerolinea int ,
@fabricante_avion varchar(30) ,
@tipo_avion varchar(30) ,
@capacidad int 
)
AS
BEGIN
SET XACT_ABORT ON
DECLARE @trans NVARCHAR(100)
SELECT @trans = 'trans_IAvion'
BEGIN TRY
BEGIN TRANSACTION @trans
				
MERGE avion AS TARGET
USING(SELECT @idavion, @idaerolinea, @fabricante_avion, @tipo_avion, @capacidad)
AS SOURCE(IDAVION, IDAEROLINEA, FABRICANTE, TIPO, CAPACIDAD)

ON (TARGET.IDAVION = SOURCE.IDAVION)

WHEN MATCHED THEN 
UPDATE SET @fabricante_avion = SOURCE.FABRICANTE, @tipo_avion = SOURCE.TIPO, @capacidad = SOURCE.CAPACIDAD
--DELETE
WHEN NOT MATCHED THEN
INSERT VALUES(SOURCE.IDAEROLINEA, SOURCE.IDAEROLINEA, SOURCE.FABRICANTE, SOURCE.TIPO, SOURCE.CAPACIDAD);
COMMIT TRANSACTION @trans
END TRY

BEGIN CATCH
			
DECLARE @STRERROR NVARCHAR(2048)
SELECT @STRERROR = ERROR_MESSAGE()
PRINT 'Ha ocurrido el siguiente error: ' + @STRERROR	
IF @@trancount > 0 and xact_state() in (1, -1)
ROLLBACK TRANSACTION @TRANS
RAISERROR ( @STRERROR, 16, 1)
END CATCH	
END 
GO

-------------------------------------------------------------------------------------
CREATE PROCEDURE SP_UIASIENTO
(
@idasiento int ,
@letra_asiento char(1) ,
@fila int 
)
AS
BEGIN
SET XACT_ABORT ON
DECLARE @trans NVARCHAR(100)
SELECT @trans = 'trans_IAsiento'
BEGIN TRY
BEGIN TRANSACTION @trans
				
MERGE asiento AS TARGET
USING(SELECT @idasiento, @letra_asiento, @fila)
AS SOURCE(IDASIENTO, LETRA, FILA)

ON (TARGET.IDASIENTO = SOURCE.IDASIENTO)

WHEN MATCHED THEN 
UPDATE SET @letra_asiento = SOURCE.LETRA, @fila = SOURCE.FILA
--DELETE
WHEN NOT MATCHED THEN
INSERT VALUES(SOURCE.IDASIENTO, SOURCE.LETRA, SOURCE.FILA);
COMMIT TRANSACTION @trans
END TRY

BEGIN CATCH
			
DECLARE @STRERROR NVARCHAR(2048)
SELECT @STRERROR = ERROR_MESSAGE()
PRINT 'Ha ocurrido el siguiente error: ' + @STRERROR	
IF @@trancount > 0 and xact_state() in (1, -1)
ROLLBACK TRANSACTION @TRANS
RAISERROR ( @STRERROR, 16, 1)
END CATCH	
END 
GO

---------------------------------------------------------------------------------------
CREATE PROCEDURE SP_UITARIFA
(
@idtarifa int ,
@clase varchar(20),
@precio money ,
@impuesto money 
)
AS
BEGIN
SET XACT_ABORT ON
DECLARE @trans NVARCHAR(100)
SELECT @trans = 'trans_ITarifa'
BEGIN TRY
BEGIN TRANSACTION @trans
				
MERGE tarifa AS TARGET
USING(SELECT @idtarifa, @clase, @precio, @impuesto)
AS SOURCE(IDTARIFA, CLASE, PRECIO, IMP)

ON (TARGET.IDTARIFA = SOURCE.IDTARIFA)

WHEN MATCHED THEN 
UPDATE SET @clase = SOURCE.CLASE, @precio = SOURCE.PRECIO, @impuesto = SOURCE.IMP
--DELETE
WHEN NOT MATCHED THEN
INSERT VALUES(SOURCE.IDTARIFA, SOURCE.CLASE, SOURCE.PRECIO, SOURCE.IMP);
COMMIT TRANSACTION @trans
END TRY

BEGIN CATCH
			
DECLARE @STRERROR NVARCHAR(2048)
SELECT @STRERROR = ERROR_MESSAGE()
PRINT 'Ha ocurrido el siguiente error: ' + @STRERROR	
IF @@trancount > 0 and xact_state() in (1, -1)
ROLLBACK TRANSACTION @TRANS
RAISERROR ( @STRERROR, 16, 1)
END CATCH	
END 
GO

---------------------------------------------------------------------------------------
CREATE PROCEDURE SP_UIRESERVA
(
@idreserva int,
@costo money ,
@fecha date ,
@observacion varchar(300)
)
AS
BEGIN
SET XACT_ABORT ON
DECLARE @trans NVARCHAR(100)
SELECT @trans = 'trans_IReserva'
BEGIN TRY
BEGIN TRANSACTION @trans
				
MERGE reserva AS TARGET
USING(SELECT @idreserva, @costo, @fecha, @observacion)
AS SOURCE(IDRESERVA, COSTO, FECHA, OBS)

ON (TARGET.IDRESERVA = SOURCE.IDRESERVA)

WHEN MATCHED THEN 
UPDATE SET @costo = SOURCE.COSTO, @fecha = SOURCE.FECHA, @observacion = SOURCE.OBS
--DELETE
WHEN NOT MATCHED THEN
INSERT VALUES(SOURCE.IDRESERVA, SOURCE.COSTO, SOURCE.FECHA, SOURCE.OBS);
COMMIT TRANSACTION @trans
END TRY

BEGIN CATCH
			
DECLARE @STRERROR NVARCHAR(2048)
SELECT @STRERROR = ERROR_MESSAGE()
PRINT 'Ha ocurrido el siguiente error: ' + @STRERROR	
IF @@trancount > 0 and xact_state() in (1, -1)
ROLLBACK TRANSACTION @TRANS
RAISERROR ( @STRERROR, 16, 1)
END CATCH	
END 
GO

--------------------------------------------------------------------------------------
CREATE PROCEDURE SP_UIPAGO
(
@idpago int,
@idreserva int ,
@idpasajero int ,
@fecha date ,
@monto money ,
@tipo_comprobante varchar(20) ,
@numero_comprobante varchar(15),
@impuesto decimal (5,2) 
)
AS
BEGIN
SET XACT_ABORT ON
DECLARE @trans NVARCHAR(100)
SELECT @trans = 'trans_IPago'
BEGIN TRY
BEGIN TRANSACTION @trans
				
MERGE pago AS TARGET
USING(SELECT @idpago, @idreserva, @idpasajero, @fecha, @monto, @tipo_comprobante, @impuesto)
AS SOURCE(IDPAGO, IDRESERVA, IDPASAJERO, FECHA, MONTO, TIPOC, IMPST)

ON (TARGET.IDPAGO = SOURCE.IDPAGO)

WHEN MATCHED THEN 
UPDATE SET  @fecha = SOURCE.FECHA, @monto = SOURCE.MONTO, @tipo_comprobante = SOURCE.TIPOC, @impuesto = SOURCE.IMPST
--DELETE
WHEN NOT MATCHED THEN
INSERT VALUES(SOURCE.IDPAGO, SOURCE.IDRESERVA, SOURCE.IDPASAJERO, SOURCE.FECHA, SOURCE.MONTO, SOURCE.IMPST);
COMMIT TRANSACTION @trans
END TRY

BEGIN CATCH
			
DECLARE @STRERROR NVARCHAR(2048)
SELECT @STRERROR = ERROR_MESSAGE()
PRINT 'Ha ocurrido el siguiente error: ' + @STRERROR	
IF @@trancount > 0 and xact_state() in (1, -1)
ROLLBACK TRANSACTION @TRANS
RAISERROR ( @STRERROR, 16, 1)
END CATCH	
END 
GO

---------------------------------------------------------------------------------------
select * from pais order by CAST(idpais as int) 

select * from pasajero 

select * from aeropuerto 

select * from aerolinea 

select * from avion 

select * from asiento 

select * from tarifa 

select * from reserva 

select * from vuelo 

select * from pago 



insert into pago (idreserva,fecha,idpasajero,monto,tipo_comprobante,
numero_comprobante,impuesto) values(1,'2015-09-12','7',10,'Factura',
'0001-00015',0.18)