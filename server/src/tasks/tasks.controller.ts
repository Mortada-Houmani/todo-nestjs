import { Body, Controller, Delete, Get, Param, Patch, Post, Put, Query, Req, Res, UseGuards } from '@nestjs/common';
import type { Request, Response } from 'express';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreateTaskDto } from './dto/create-task.dto';
import { UpdateTaskDto } from './dto/update-task.dto';
import { TasksService } from './tasks.service';

@Controller('tasks')
@UseGuards(JwtAuthGuard)
export class TasksController {
  constructor(private readonly tasksService: TasksService) {}

  @Get()
  async list(@Req() req: Request & { user?: { userId: number } }, @Query('query') query?: string) {
    return this.tasksService.listForUser(req.user!.userId, query);
  }

  @Post()
  async create(@Req() req: Request & { user?: { userId: number } }, @Body() dto: CreateTaskDto) {
    return this.tasksService.createForUser(req.user!.userId, dto.text);
  }

  // Existing Express used PUT;
  @Put(':id')
  async putUpdate(@Req() req: Request & { user?: { userId: number } }, @Param('id') id: string, @Body() dto: UpdateTaskDto) {
    return this.tasksService.updateForUser(req.user!.userId, Number(id), dto);
  }

  @Patch(':id')
  async patchUpdate(@Req() req: Request & { user?: { userId: number } }, @Param('id') id: string, @Body() dto: UpdateTaskDto) {
    return this.tasksService.updateForUser(req.user!.userId, Number(id), dto);
  }

  @Delete(':id')
  async remove(
    @Req() req: Request & { user?: { userId: number } },
    @Param('id') id: string,
    @Res() res: Response,
  ) {
    await this.tasksService.deleteForUser(req.user!.userId, Number(id));
    return res.sendStatus(204);
  }
}

