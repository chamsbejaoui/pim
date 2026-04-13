import { PartialType } from '@nestjs/mapped-types';
import { CreateTestTypeDto } from './create-test-type.dto';

export class UpdateTestTypeDto extends PartialType(CreateTestTypeDto) { }
