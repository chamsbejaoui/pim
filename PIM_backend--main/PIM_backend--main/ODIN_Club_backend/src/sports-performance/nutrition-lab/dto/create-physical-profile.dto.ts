import { IsString, IsNumber, IsNotEmpty, Min, Max, IsDateString } from 'class-validator';

export class CreatePhysicalProfileDto {
  @IsString()
  @IsNotEmpty()
  userId: string;

  @IsNumber()
  weightKg: number;

  @IsNumber()
  heightCm: number;

  @IsNumber()
  @Min(50) @Max(150)
  tourTaille: number;

  @IsNumber()
  @Min(20) @Max(60)
  tourCou: number;

  @IsDateString()
  dateNaissance: string;

  @IsString()
  position: string;
}
