import { Column, Entity, OneToMany, PrimaryGeneratedColumn } from 'typeorm';
import { Task } from '../tasks/task.entity';

@Entity({ name: 'users' })
export class User {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ type: 'text', unique: true })
  email!: string;

  @Column({ type: 'text' })
  fullName!: string;

  @Column({ type: 'text' })
  password!: string;

  @Column({ default: false })
  isEmailVerified!: boolean;

  @OneToMany(() => Task, (task) => task.user, { cascade: true })
  tasks!: Task[];
}