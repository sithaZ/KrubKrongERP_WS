import { Entity, Column, PrimaryGeneratedColumn } from 'typeorm';

@Entity('users') 
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  username: string;

  @Column()
  password: string;


  //roles
  @Column({ default: 'STAFF' })
  role: string;
  //active status
  @Column({ default: true })
  isActive: boolean;

  @Column({ nullable: true })
  email: string;

}