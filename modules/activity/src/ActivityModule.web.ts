import { registerWebModule, NativeModule } from 'expo';

import { ChangeEventPayload } from './Activity.types';

type ActivityModuleEvents = {
  onChange: (params: ChangeEventPayload) => void;
}

class ActivityModule extends NativeModule<ActivityModuleEvents> {
  PI = Math.PI;
  async setValueAsync(value: string): Promise<void> {
    this.emit('onChange', { value });
  }
  hello() {
    return 'Hello world! 👋';
  }
};

export default registerWebModule(ActivityModule, 'ActivityModule');
