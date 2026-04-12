import { Role } from '../../common/enums/role.enum';
import { canDeleteMessageForEveryone } from './delete-scope.util';

describe('canDeleteMessageForEveryone', () => {
  it('allows sender', () => {
    expect(
      canDeleteMessageForEveryone({
        actorUserId: 'user-1',
        senderUserId: 'user-1',
        actorRole: Role.JOUEUR
      })
    ).toBe(true);
  });

  it('allows role with moderation permission', () => {
    expect(
      canDeleteMessageForEveryone({
        actorUserId: 'responsable',
        senderUserId: 'other-user',
        actorRole: Role.CLUB_RESPONSABLE
      })
    ).toBe(true);
  });

  it('rejects standard players deleting others globally', () => {
    expect(
      canDeleteMessageForEveryone({
        actorUserId: 'player-a',
        senderUserId: 'player-b',
        actorRole: Role.JOUEUR
      })
    ).toBe(false);
  });
});
