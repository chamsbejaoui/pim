import { IsInt, Max, Min } from "class-validator";
export class MedicalInputDto {
  @IsInt()
  @Min(0)
  @Max(100)
  age!: number;

  @IsInt()
  @Min(0)
  @Max(100)
  fitness!: number;

  @IsInt()
  @Min(0)
  @Max(100)
  fatigue!: number;

  @IsInt()
  @Min(0)
  @Max(120)
  minutes!: number;

  @IsInt()
  @Min(0)
  @Max(100)
  load!: number;

  @IsInt()
  @Min(0)
  @Max(20)
  history!: number;
}