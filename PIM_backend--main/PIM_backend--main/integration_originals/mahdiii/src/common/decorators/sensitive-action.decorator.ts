import { SetMetadata } from '@nestjs/common';
import { SensitiveActionMetadata } from '../interfaces/sensitive-action-metadata.interface';

export const SENSITIVE_ACTION_KEY = 'sensitiveAction';
export const SensitiveAction = (metadata: SensitiveActionMetadata) =>
  SetMetadata(SENSITIVE_ACTION_KEY, metadata);
