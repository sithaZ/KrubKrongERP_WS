import { IsMongoId } from 'class-validator';

export class AssignCompanyManagerDto {
  @IsMongoId()
  managerId: string;
}
