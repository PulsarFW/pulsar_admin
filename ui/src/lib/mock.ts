// dev-only simulated Lua message stream, just SET_USERDATA + APP_SHOW. this resource pulls list/detail data through
// NUI-callback responses, not push messages, so nui.ts's request wrappers already return realistic mock data (mockData.ts)

import { applyMessage } from './messages';

export function startMock(): void {
	setTimeout(() => {
		applyMessage('SET_USERDATA', {
			user: { Source: 10, Name: 'Dr Nick', AccountID: 25, Identifier: '789723918798237', Groups: [7] },
			permission: 'Management',
			permissionName: 'Management',
			permissionLevel: 100,
		});
		applyMessage('APP_SHOW', {});
	}, 200);
}
