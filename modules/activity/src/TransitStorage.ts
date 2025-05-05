import { requireNativeModule } from "expo";

interface TransitStorageModuleType {
  set(appGroup: string, key: string, value: any): void;
  reloadWidget(): void;
}

class TransitStorage {
  private appGroup: string;

  constructor(appGroup: string) {
    this.appGroup = appGroup;
  }

  set(key: string, value: any): void {
    const module =
      requireNativeModule<TransitStorageModuleType>("TransitStorage");
    module.set(this.appGroup, key, value);
  }

  static reloadWidget(): void {
    const module =
      requireNativeModule<TransitStorageModuleType>("TransitStorage");
    module.reloadWidget();
  }
}

export default TransitStorage;
