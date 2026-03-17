import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Like, Repository } from 'typeorm';
import { Task } from './task.entity';

@Injectable()
export class TasksService {
  constructor(
    @InjectRepository(Task)
    private readonly tasksRepo: Repository<Task>,
  ) {}

  listForUser(userId: number, query?: string) {
    const where = query ? { text: Like(`%${query}%`), userId } : { userId };
    return this.tasksRepo.find({ where });
  }

  async createForUser(userId: number, text: string) {
    const task = this.tasksRepo.create({ text, completed: false, userId });
    return this.tasksRepo.save(task);
  }

  async updateForUser(userId: number, id: number, patch: Partial<Pick<Task, 'text' | 'completed'>>) {
    const task = await this.tasksRepo.findOne({ where: { id, userId } });
    if (!task) {
      throw new NotFoundException('Task not found');
    }

    if (patch.text !== undefined) task.text = patch.text;
    if (patch.completed !== undefined) task.completed = patch.completed;
    return this.tasksRepo.save(task);
  }

  async deleteForUser(userId: number, id: number) {
    // Keep 204 behavior while preventing cross-user deletes.
    await this.tasksRepo.delete({ id, userId });
  }
}

