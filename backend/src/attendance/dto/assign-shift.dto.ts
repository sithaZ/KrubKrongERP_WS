import { IsMongoId } from 'class-validator';

export class AssignShiftDto {
  @IsMongoId()
  employeeId: string;

  @IsMongoId()
  shiftId: string;
}
