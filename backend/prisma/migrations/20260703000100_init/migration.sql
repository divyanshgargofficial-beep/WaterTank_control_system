CREATE TYPE "UserRole" AS ENUM ('ADMIN', 'FAMILY');
CREATE TYPE "CommandType" AS ENUM ('PUMP_ON', 'PUMP_OFF', 'RESET_LOCKOUT');
CREATE TYPE "CommandStatus" AS ENUM ('PENDING', 'DELIVERED', 'ACKED', 'FAILED');
CREATE TYPE "HistoryType" AS ENUM ('PUMP_STARTED', 'PUMP_STOPPED', 'TANK_FULL', 'LOCKOUT_ACTIVATED', 'LOCKOUT_RESET', 'CONTROLLER_OFFLINE', 'CONTROLLER_ONLINE', 'STATUS_SYNC', 'COMMAND_ACKED');
CREATE TYPE "NotificationType" AS ENUM ('PUMP_STARTED', 'PUMP_STOPPED', 'TANK_FULL', 'CONTROLLER_OFFLINE', 'CONTROLLER_ONLINE', 'LOCKOUT_ACTIVATED');

CREATE TABLE "User" (
  "id" TEXT NOT NULL,
  "email" TEXT NOT NULL,
  "name" TEXT NOT NULL,
  "role" "UserRole" NOT NULL,
  "passwordHash" TEXT NOT NULL,
  "active" BOOLEAN NOT NULL DEFAULT true,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "Device" (
  "id" TEXT NOT NULL,
  "deviceId" TEXT NOT NULL,
  "deviceName" TEXT NOT NULL,
  "firmwareVersion" TEXT,
  "deviceTokenHash" TEXT NOT NULL,
  "lastSeen" TIMESTAMP(3),
  "online" BOOLEAN NOT NULL DEFAULT false,
  "pumpRunning" BOOLEAN NOT NULL DEFAULT false,
  "tankFull" BOOLEAN NOT NULL DEFAULT false,
  "lockout" BOOLEAN NOT NULL DEFAULT false,
  "runtime" INTEGER NOT NULL DEFAULT 0,
  "totalRuntime" INTEGER NOT NULL DEFAULT 0,
  "wifiRSSI" INTEGER,
  "ipAddress" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "Device_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "Command" (
  "id" TEXT NOT NULL,
  "deviceId" TEXT NOT NULL,
  "requestedBy" TEXT,
  "type" "CommandType" NOT NULL,
  "status" "CommandStatus" NOT NULL DEFAULT 'PENDING',
  "payload" JSONB,
  "deliveredAt" TIMESTAMP(3),
  "ackedAt" TIMESTAMP(3),
  "error" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "Command_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "DeviceStatus" (
  "id" TEXT NOT NULL,
  "deviceId" TEXT NOT NULL,
  "pumpRunning" BOOLEAN NOT NULL,
  "tankFull" BOOLEAN NOT NULL,
  "lockout" BOOLEAN NOT NULL,
  "runtime" INTEGER NOT NULL,
  "totalRuntime" INTEGER NOT NULL,
  "wifiRSSI" INTEGER,
  "ipAddress" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "DeviceStatus_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "Session" (
  "id" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "tokenHash" TEXT NOT NULL,
  "userAgent" TEXT,
  "ipAddress" TEXT,
  "expiresAt" TIMESTAMP(3) NOT NULL,
  "revokedAt" TIMESTAMP(3),
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "Session_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "Notification" (
  "id" TEXT NOT NULL,
  "userId" TEXT,
  "deviceId" TEXT NOT NULL,
  "type" "NotificationType" NOT NULL,
  "title" TEXT NOT NULL,
  "body" TEXT NOT NULL,
  "read" BOOLEAN NOT NULL DEFAULT false,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "Notification_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "History" (
  "id" TEXT NOT NULL,
  "deviceId" TEXT NOT NULL,
  "userId" TEXT,
  "type" "HistoryType" NOT NULL,
  "message" TEXT NOT NULL,
  "metadata" JSONB,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "History_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "User_email_key" ON "User"("email");
CREATE UNIQUE INDEX "Device_deviceId_key" ON "Device"("deviceId");

ALTER TABLE "Command" ADD CONSTRAINT "Command_deviceId_fkey" FOREIGN KEY ("deviceId") REFERENCES "Device"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Command" ADD CONSTRAINT "Command_requestedBy_fkey" FOREIGN KEY ("requestedBy") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "DeviceStatus" ADD CONSTRAINT "DeviceStatus_deviceId_fkey" FOREIGN KEY ("deviceId") REFERENCES "Device"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Session" ADD CONSTRAINT "Session_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Notification" ADD CONSTRAINT "Notification_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "Notification" ADD CONSTRAINT "Notification_deviceId_fkey" FOREIGN KEY ("deviceId") REFERENCES "Device"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "History" ADD CONSTRAINT "History_deviceId_fkey" FOREIGN KEY ("deviceId") REFERENCES "Device"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "History" ADD CONSTRAINT "History_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
