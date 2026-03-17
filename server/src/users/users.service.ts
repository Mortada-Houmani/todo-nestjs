import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly usersRepo: Repository<User>,
  ) {}

  findByEmail(email: string) {
    return this.usersRepo.findOne({ where: { email } });
  }

  create(user: Pick<User, 'email' | 'fullName' | 'password'>) {
    const entity = this.usersRepo.create(user);
    return this.usersRepo.save(entity);
  }

  async save(user: User) {
  return this.usersRepo.save(user);
 
}
async findById(id: number) {
  return this.usersRepo.findOne({ where: { id } });
}
async update(id: number, data: Partial<User>) {
  await this.usersRepo.update(id, data);
  return this.findById(id);
}

  async delete(id: number) {
    await this.usersRepo.delete(id);
  }
}
