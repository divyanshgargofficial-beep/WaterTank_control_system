export interface StatusPayload {
  deviceId: string;
  pumpRunning: boolean;
  tankFull: boolean;
  lockout: boolean;
  runtime: number;
  totalRuntime: number;
  wifiRSSI?: number;
  ipAddress?: string;
  firmwareVersion?: string;
}
