import * as React from 'react';

import { ActivityViewProps } from './Activity.types';

export default function ActivityView(props: ActivityViewProps) {
  return (
    <div>
      <iframe
        style={{ flex: 1 }}
        src={props.url}
        onLoad={() => props.onLoad({ nativeEvent: { url: props.url } })}
      />
    </div>
  );
}
