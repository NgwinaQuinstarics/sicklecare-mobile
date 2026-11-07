import {
  parseAdminHomeContentRequest,
  parseAdminInboxUpdateRequest,
} from './request_validation';

describe('parseAdminInboxUpdateRequest', () => {
  it('accepts supported inbox state changes', () => {
    expect(parseAdminInboxUpdateRequest({
      id: 'request-1',
      kind: 'support_messages',
      status: 'in_progress',
    })).toEqual({
      id: 'request-1',
      kind: 'support_messages',
      status: 'in_progress',
    });

  });

  it('accepts closed legacy requests', () => {
    expect(parseAdminInboxUpdateRequest({
      id: 'legacy-request',
      kind: 'contacts',
      status: 'closed',
    }).status).toBe('closed');
  });

  it.each([
    null,
    [],
    { id: '', kind: 'contacts', status: 'new' },
    { id: 'x'.repeat(129), kind: 'contacts', status: 'new' },
    { id: 'id', kind: 'users', status: 'new' },
    { id: 'id', kind: 'contacts', status: 'admin' },
    { id: 'id', kind: 'contacts', status: 'new', uid: 'attacker' },
  ])('rejects invalid inbox updates: %p', (request) => {
    expect(() => parseAdminInboxUpdateRequest(request)).toThrow(TypeError);
  });
});

describe('parseAdminHomeContentRequest', () => {
  it('trims and validates published text', () => {
    expect(parseAdminHomeContentRequest({
      heroTitle: '  Welcome  ',
      heroBody: '  Take care.  ',
    })).toEqual({ heroTitle: 'Welcome', heroBody: 'Take care.' });
  });

  it.each([
    null,
    [],
    { heroTitle: '', heroBody: 'Message' },
    { heroTitle: 'Title', heroBody: ' '.repeat(2) },
    { heroTitle: 'x'.repeat(121), heroBody: 'Message' },
    { heroTitle: 'Title', heroBody: 'x'.repeat(2001) },
    { heroTitle: 'Title', heroBody: 'Message', admin: true },
  ])('rejects invalid published content: %p', (request) => {
    expect(() => parseAdminHomeContentRequest(request)).toThrow(TypeError);
  });
});
